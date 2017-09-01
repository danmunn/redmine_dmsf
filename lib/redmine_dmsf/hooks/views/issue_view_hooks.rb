# encoding: utf-8
#
# Redmine plugin for Document Management System "Features"
#
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

module RedmineDmsf
  module Hooks
    include Redmine::Hook

    class DmsfViewListener < Redmine::Hook::ViewListener

      def view_issues_form_details_bottom(context={})
        return if defined?(EasyExtensions)
        context[:container] = context[:issue]
        attach_documents_form(context)
      end

      def view_issues_edit_notes_bottom(context={})
        html = ''
        # Radio buttons
        if allowed_to_attach_documents(context[:container])
          html << '<p>'
            html << '<label class="inline">'
              html << radio_button_tag('dmsf_attachments_upload_choice', 'Attachments',
                    User.current.pref.dmsf_attachments_upload_choice == 'Attachments',
                    onchange: "$('.attachments-container').parent().show(); $('.dmsf_uploader').parent().hide(); return false;")
              html << l(:label_basic_attachments)
            html << '</label>'
            html << '<label class="inline">'
              html << radio_button_tag('dmsf_attachments_upload_choice', 'DMSF',
                    User.current.pref.dmsf_attachments_upload_choice == 'DMSF',
                    onchange: "$('.attachments-container').parent().hide(); $('.dmsf_uploader').parent().show(); return false;")
              html << l(:label_dmsf_attachments)
            html << '</label>'
          html << '</p>'
        end
        # Upload form
        html.html_safe + attach_documents_form(context, false,
          defined?(EasyExtensions) && EasySetting.value('attachment_description'))
      end

      def view_issues_show_description_bottom(context={})
        return if defined?(EasyExtensions)
        show_attached_documents(context[:issue], context[:controller])
      end

      def view_issues_show_attachments_bottom(context={})
        unless context[:options][:only_mails].present?
          show_attached_documents(context[:container], context[:controller], context[:attachments])
        end
      end

      def view_issues_dms_attachments(context={})
        'yes' if get_links(context[:container]).any?
      end

      def view_issues_show_thumbnails(context={})
        show_thumbnails(context[:container], context[:controller])
      end

      def view_issues_dms_thumbnails(context={})
        unless context[:options][:only_mails].present?
          links = get_links(context[:container])
          if links.present? && Setting.thumbnails_enabled?
            images = links.map{ |x| x[0] }.select(&:image?)
            return 'yes' if images.any?
          end
        end
      end

      def view_issues_edit_notes_bottom_style(context={})
        if (User.current.pref[:dmsf_attachments_upload_choice] == 'Attachments') ||
          !allowed_to_attach_documents(context[:container])
          ''
        else
          'display: none'
        end
      end

      private

      def allowed_to_attach_documents(container)
        container &&
          User.current.allowed_to?(:file_manipulation, container.project) &&
          Setting.plugin_redmine_dmsf['dmsf_act_as_attachable'] &&
          (container.project.dmsf_act_as_attachable == Project::ATTACHABLE_DMS_AND_ATTACHMENTS)
      end

      def get_links(container)
        links = []
        if defined?(container.dmsf_files) && User.current.allowed_to?(:view_dmsf_files, container.project) &&
          Setting.plugin_redmine_dmsf['dmsf_act_as_attachable'] &&
          (container.project.dmsf_act_as_attachable == Project::ATTACHABLE_DMS_AND_ATTACHMENTS)
          for dmsf_file in container.dmsf_files
            if dmsf_file.last_revision
              links << [dmsf_file, nil, dmsf_file.created_at]
            end
          end
          for dmsf_link in container.dmsf_links
            dmsf_file = dmsf_link.target_file
            if dmsf_file && dmsf_file.last_revision
              links << [dmsf_file, dmsf_link, dmsf_link.created_at]
            end
          end
          # Sort by 'create_at'
          links.sort!{ |x, y| x[2] <=> y[2] }
        end
        links
      end

      def show_thumbnails(container, controller)
        links = get_links(container)
        if links.present?
          html = controller.send(:render_to_string,
            { :partial => 'dmsf_files/thumbnails',
              :locals => { :links => links, :thumbnails => Setting.thumbnails_enabled?, :link_to => false } })
          html.html_safe
        end
      end

      def attach_documents_form(context, label=true, description=true)
        if context.is_a?(Hash) && context[:container]
          # Add Dmsf upload form
          container = context[:container]
          if allowed_to_attach_documents(container)
            html = "<p style=\"#{(User.current.pref[:dmsf_attachments_upload_choice] == 'Attachments') ? 'display: none;' : ''}\">"
            if label
              html << "<label>#{l(:label_document_plural)}</label>"
              html << "<span class=\"attachments-container dmsf_uploader\">"
            else
              html << "<span class=\"attachments-container dmsf_uploader\" style=\"border: 2px dashed #dfccaf; background: none;\">"
            end
                html << context[:controller].send(:render_to_string,
                  { :partial => 'dmsf_upload/form',
                    :locals => { :container => container, :multiple => true, :description => description, :awf => true }})
              html << '</span>'
            html << '</p>'
            html.html_safe
          end
        end
      end

      def show_attached_documents(container, controller, attachments=nil)
        # Add list of attached documents
        links = get_links(container)
        if links.present?
          unless defined?(EasyExtensions)
            controller.send(:render_to_string, {:partial => 'dmsf_files/links',
              :locals => { :links => links, :thumbnails => Setting.thumbnails_enabled? }})
          else
            attachment_rows(links, container, controller, attachments)
          end
        end
      end

      def attachment_rows(links, issue, controller, attachments)
        if links.any?
          html = '<tbody>'
          if attachments.any?
            html << "<tr><th colspan=\"4\">#{l(:label_dmsf_attachments)} (#{links.count})</th></tr>"
          end
          links.each do |dmsf_file, link, create_at|
            html << attachment_row(dmsf_file, link, issue, controller)
          end
          html << '</tbody>'
          html.html_safe
        end
      end

      def attachment_row(dmsf_file, link, issue, controller)
        if link
          html = '<tr class="dmsf_gray">'
        else
          html = '<tr>'
        end
        # Checkbox
        show_checkboxes = true #options[:show_checkboxes].nil? ? true : options[:show_checkboxes]
        if show_checkboxes
          html << '<td></td>'
        end
        file_view_url = url_for({:controller => :dmsf_files, :action => 'view', :id => dmsf_file})
        # Title, size
        html << '<td>'
          html << link_to(h(dmsf_file.title),file_view_url, :target => '_blank',
            :class => "icon icon-file #{DmsfHelper.filetype_css(dmsf_file.name)}",
            :title => h(dmsf_file.last_revision.try(:tooltip)),
            'data-downloadurl' => "#{dmsf_file.last_revision.detect_content_type}:#{h(dmsf_file.name)}:#{file_view_url}")
          html << "<span class=\"size\">(#{number_to_human_size(dmsf_file.last_revision.size)})</span>"
          html << " - #{dmsf_file.description}" unless dmsf_file.description.blank?
        html << '</td>'
        # Author, updated at
        html << '<td>'
          html << "<span class=\"author\">#{dmsf_file.last_revision.user}, #{format_time(dmsf_file.last_revision.updated_at)}</span>"
        html << '</td>'
        # Command icons
        html << '<td class="fast-icons easy-query-additional-ending-buttons hide-when-print">'
          # Details
          if User.current.allowed_to? :file_manipulation, dmsf_file.project
            html << link_to('', dmsf_file_path(:id => dmsf_file),
              :title => l(:link_details, :title => h(dmsf_file.last_revision.title)),
              :class => 'icon icon-edit')
          else
            html << '<span class="icon"></span>'
          end
          # Email
          html << link_to('', entries_operations_dmsf_path(:id => dmsf_file.project,
            :email_entries => 'email', :files => [dmsf_file.id]), :method => :post,
            :title => l(:heading_send_documents_by_email), :class => 'icon icon-email-disabled')
          # Lock
          if !dmsf_file.locked?
            html << link_to('', lock_dmsf_files_path(:id => dmsf_file),
            :title => l(:title_loc_file), :class => 'icon icon-lock')
          elsif dmsf_file.unlockable? && (!dmsf_file.locked_for_user? || User.current.allowed_to?(:force_file_unlock, dmsf_file.project))
            html << link_to('', unlock_dmsf_files_path(:id => dmsf_file),
              :title => dmsf_file.get_locked_title, :class => 'icon icon-unlock')
          else
            html << "<span class=\"icon icon-unlock\" title=\"#{dmsf_file.get_locked_title}\"></span>"
          end
          unless dmsf_file.locked?
            # Notifications
            if dmsf_file.notification
              html << link_to('',notify_deactivate_dmsf_files_path(:id => dmsf_file),
                :title => l(:title_notifications_active_deactivate), :class => 'icon icon-email')
            else
              html << link_to('',notify_activate_dmsf_files_path(:id => dmsf_file),
                :title => l(:title_notifications_not_active_activate), :class => 'icon icon-email-add')
            end
            # Delete
            if issue.attributes_editable?  && User.current.allowed_to?(:file_delete, dmsf_file.project)
              html << link_to('',
                link ? dmsf_link_path(link, :commit => 'yes') : dmsf_file_path(:id => dmsf_file, :commit => 'yes'),
                :data => {:confirm => l(:text_are_you_sure)}, :method => :delete, :title => l(:title_delete),
                :class => 'icon icon-del')
            end
          else
            html << '<span class="icon"></span>' * 2
          end
          # Approval workflow
          wf = DmsfWorkflow.find_by_id(dmsf_file.last_revision.dmsf_workflow_id) if dmsf_file.last_revision.dmsf_workflow_id
          html << controller.send(:render_to_string, {:partial => 'dmsf_workflows/approval_workflow_button',
            :locals => {:file => dmsf_file,
              :file_approval_allowed => User.current.allowed_to?(:file_approval, dmsf_file.project),
              :workflows_available => DmsfWorkflow.where(['project_id = ? OR project_id IS NULL', dmsf_file.project.id]).exists?,
              :project => dmsf_file.project, :wf => wf, :dmsf_link_id => nil }})         
        html << '</td>'
        html << '</tr>'
        html
      end

    end
  end
end
