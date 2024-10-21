# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Vít Jonáš <vit.jonas@gmail.com>, Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# Upload controller
class DmsfUploadController < ApplicationController
  menu_item :dmsf

  before_action :find_project, except: %i[upload delete_dmsf_attachment delete_dmsf_link_attachment]
  before_action :authorize, except: %i[upload delete_dmsf_attachment delete_dmsf_link_attachment]
  before_action :authorize_global, only: %i[upload delete_dmsf_attachment delete_dmsf_link_attachment]
  before_action :find_folder, except: %i[upload commit delete_dmsf_attachment delete_dmsf_link_attachment]
  before_action :permissions, except: %i[upload commit delete_dmsf_attachment delete_dmsf_link_attachment]

  helper :custom_fields
  helper :dmsf_workflows
  helper :dmsf

  accept_api_auth :upload, :commit

  def permissions
    render_403 unless DmsfFolder.permissions?(@folder)
    true
  end

  def upload_files
    uploaded_files = params[:dmsf_attachments]
    @uploads = []
    # Commit
    if params[:commit] == l(:label_dmsf_upload_commit)
      uploaded_files&.each do |key, uploaded_file|
        upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, uploaded_file)
        next unless upload

        @uploads.push upload
        params[:committed_files][key][:disk_filename] = upload.disk_filename
        params[:committed_files][key][:digest] = upload.digest
        params[:committed_files][key][:tempfile_path] = upload.tempfile_path
      end
      commit_files if params[:committed_files].present?
    # Upload
    else
      # standard file input uploads
      uploaded_files&.each do |_, uploaded_file|
        upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, uploaded_file)
        @uploads.push(upload) if upload
      end
    end
    flash.now[:error] = "#{l(:label_attachment)} #{l('activerecord.errors.messages.invalid')}" if @uploads.empty?
  end

  # REST API and Redmine attachment form
  def upload
    unless request.media_type == 'application/octet-stream'
      head :not_acceptable
      return
    end

    @attachment = Attachment.new(file: request.body)
    @attachment.author = User.current
    @attachment.filename = params[:filename].presence || Redmine::Utils.random_hex(16)
    @attachment.content_type = params[:content_type].presence
    @attachment.skip_description_required = true if defined?(EasyExtensions)
    begin
      Attachment.skip_callback(:commit, :after, :reuse_existing_file_if_possible, raise: false)
      saved = @attachment.save
    ensure
      Attachment.set_callback(:commit, :after, :reuse_existing_file_if_possible)
    end

    respond_to do |format|
      format.js
      format.api do
        if saved
          render action: 'upload', status: :created
        else
          render_validation_errors @attachment
        end
      end
    end
  end

  def commit_files
    commit_files_internal params[:committed_files]
  end

  # REST API file commit
  def commit
    @files = []
    attachments = params[:attachments]
    return unless attachments

    @folder = DmsfFolder.visible.find_by(id: attachments[:folder_id]) if attachments[:folder_id].present?
    # standard file input uploads
    uploaded_files = attachments.select { |key, _| key == 'uploaded_file' }
    uploaded_files.each do |_, uploaded_file|
      upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, uploaded_file)
      next unless upload

      uploaded_file[:disk_filename] = upload.disk_filename
      uploaded_file[:tempfile_path] = upload.tempfile_path
      uploaded_file[:size] = upload.size
      uploaded_file[:digest] = upload.digest
      uploaded_file[:mime_type] = upload.mime_type
    end
    commit_files_internal uploaded_files
  end

  def delete_dmsf_attachment
    attachment = Attachment.find(params[:id])
    attachment.destroy
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def delete_dmsf_link_attachment
    link = DmsfLink.find(params[:id])
    link.destroy
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def commit_files_internal(committed_files)
    @files, failed_uploads = DmsfUploadHelper.commit_files_internal(committed_files, @project, @folder, self)
    call_hook :dmsf_upload_controller_after_commit, { files: @files }
    respond_to do |format|
      format.js
      format.api  { render_validation_errors(failed_uploads) unless failed_uploads.empty? }
      format.html { redirect_to dmsf_folder_path(id: @project, folder_id: @folder) }
    end
  end

  def find_folder
    @folder = DmsfFolder.visible.find(params[:folder_id]) if params.key?('folder_id')
  rescue RedmineDmsf::Errors::DmsfAccessError
    render_403
  end
end
