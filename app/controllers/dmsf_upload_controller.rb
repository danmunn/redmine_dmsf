# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
# Copyright (C) 2011    Vít Jonáš <vit.jonas@gmail.com>
# Copyright (C) 2011-17 Karel Pičman <karel.picman@kontron.com>
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

class DmsfUploadController < ApplicationController
  unloadable

  menu_item :dmsf

  before_filter :find_project, :except => [:upload, :delete_dmsf_attachment]
  before_filter :authorize, :except => [:upload, :delete_dmsf_attachment]
  before_filter :authorize_global, :only => [:upload, :delete_dmsf_attachment]
  before_filter :find_folder, :except => [:upload_file, :upload, :commit, :delete_dmsf_attachment]

  helper :all
  helper :dmsf_workflows

  accept_api_auth :upload, :commit

  def upload_files
    uploaded_files = params[:dmsf_attachments]
    @uploads = []
    if uploaded_files && uploaded_files.is_a?(Hash)
      # standard file input uploads
      uploaded_files.each_value do |uploaded_file|
        upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, uploaded_file)
        @uploads.push(upload) if upload
      end
    else
      # plupload multi upload completed
      uploaded = params[:uploaded]
      if uploaded && uploaded.is_a?(Hash)
        uploaded.each_value do |uploaded_file|
          @uploads.push(DmsfUpload.new(@project, @folder, uploaded_file))
        end
      end
    end
  end

  # async single file upload handling
  def upload_file
    @tempfile = params[:file]
    unless @tempfile.original_filename
      render_404
      return
    end
    @disk_filename = DmsfHelper.temp_filename(@tempfile.original_filename)
    target = "#{DmsfHelper.temp_dir}/#{@disk_filename}"
    begin
      FileUtils.cp @tempfile.path, target
      FileUtils.chmod 'u=wr,g=r', target
    rescue Exception => e
      Rails.logger.error e.message
    end
    if File.size(target) <= 0
      begin
        File.delete target
      rescue Exception => e
        Rails.logger.error e.message
      end
      render :layout => nil, :json => { :jsonrpc => '2.0',
        :error => {
          :code => 103,
          :message => l(:header_minimum_filesize),
          :details => l(:error_minimum_filesize,
          :file => @tempfile.original_filename.to_s)
        }
      }
    else
      render :layout => false
    end
  end

  # REST API document upload
  def upload
    unless request.content_type == 'application/octet-stream'
      render :nothing => true, :status => 406
      return
    end

    @attachment = Attachment.new(:file => request.raw_post)
    @attachment.author = User.current
    @attachment.filename = params[:filename].presence || Redmine::Utils.random_hex(16)
    @attachment.content_type = params[:content_type].presence
    saved = @attachment.save

    respond_to do |format|
      format.js
      format.api {
        if saved
          render :action => 'upload', :status => :created
        else
          render_validation_errors(@attachment)
        end
      }
    end
  end

  def commit_files
    commit_files_internal params[:commited_files]
  end

  # REST API file commit
  def commit
    @files = []
    attachments = params[:attachments]
    if attachments && attachments.is_a?(Hash)
      @folder = DmsfFolder.visible.find_by_id attachments[:folder_id].to_i if attachments[:folder_id].present?
      # standard file input uploads
      uploaded_files = attachments.select { |key, value| key == 'uploaded_file'}
      uploaded_files.each_value do |uploaded_file|
        upload = DmsfUpload.create_from_uploaded_attachment(@project, @folder, uploaded_file)
        uploaded_file[:disk_filename] = upload.disk_filename
      end
      commit_files_internal uploaded_files
    end
  end

  def delete_dmsf_attachment
    attachment = Attachment.find(params[:id])
    attachment.destroy
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  private

  def commit_files_internal(commited_files)
    @files, failed_uploads = DmsfUploadHelper.commit_files_internal(commited_files, @project, @folder, self)
    respond_to do |format|
      format.js
      format.api  { render_validation_errors(failed_uploads) unless failed_uploads.empty? }
      format.html { redirect_to dmsf_folder_path(:id => @project, :folder_id => @folder) }
    end
  end

  def find_folder
    @folder = DmsfFolder.visible.find(params[:folder_id]) if params.keys.include?('folder_id')
  rescue DmsfAccessError
    render_403
  end

end
