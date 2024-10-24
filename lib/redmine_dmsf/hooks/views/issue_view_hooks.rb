# frozen_string_literal: true

# Redmine plugin for Document Management System "Features"
#
# Karel Pičman <karel.picman@kontron.com>
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
    module Views
      # Issue view hooks
      class IssueViewHooks < Redmine::Hook::ViewListener
        def view_issues_form_details_bottom(context = {})
          return if defined?(EasyExtensions)

          context[:container] = context[:issue]
          attach_documents_form(context)
        end

        def view_attachments_form_top(context = {})
          html = +''
          container = context[:container]
          description = defined?(EasyExtensions) && EasySetting.value('attachment_description')
          # Radio buttons
          if allowed_to_attach_documents(container) && allowed_to_attach_attachments(container)
            html << (description ? '<p>' : '<div>')
            classes = +'inline'
            html << "<label class=\"#{classes}\">"
            onchange = %($(".attachments-container:not(.dmsf-uploader)").show();
                         $(".dmsf-uploader").parent().hide();
                         return false;)
            html << radio_button_tag('dmsf_attachments_upload_choice', 'Attachments',
                                     User.current.pref.dmsf_attachments_upload_choice == 'Attachments',
                                     onchange: onchange)
            html << l(:label_basic_attachments)
            html << '</label>'
            classes << ' dmsf_attachments_label' unless container&.new_record?
            html << "<label class=\"#{classes}\">"
            onchange = %($(".attachments-container:not(.dmsf-uploader)").hide();
                         $(".dmsf-uploader").parent().show();
                         return false;)
            html << radio_button_tag('dmsf_attachments_upload_choice', 'DMSF',
                                     User.current.pref.dmsf_attachments_upload_choice == 'DMSF',
                                     onchange: onchange)
            html << l(:label_dmsf_attachments)
            html << '</label>'
            html << (description ? '</p>' : '</div>')
            if User.current.pref.dmsf_attachments_upload_choice == 'DMSF'
              html << context[:hook_caller].late_javascript_tag(
                "$('.attachments-container:not(.dmsf-uploader)').hide();"
              )
            end
          end
          # Upload form
          if allowed_to_attach_documents(container)
            html << attach_documents_form(context, label: false, description: description)
          end
          unless allowed_to_attach_attachments(container)
            html << context[:hook_caller].late_javascript_tag("$('.attachments-container:not(.dmsf-uploader)').hide();")
          end
          html
        end

        def view_issues_show_description_bottom(context = {})
          return if defined?(EasyExtensions)

          show_attached_documents context[:issue], context[:controller]
        end

        def view_issues_show_attachments_table_bottom(context = {})
          show_attached_documents context[:container], context[:controller], context[:attachments]
        end

        def view_issues_dms_attachments(context = {})
          'yes' if get_links(context[:container]).any?
        end

        def view_issues_show_thumbnails(context = {})
          show_thumbnails(context[:container], context[:controller])
        end

        def view_issues_dms_thumbnails(context = {})
          links = get_links(context[:container])
          return unless links.present? && Setting.thumbnails_enabled?

          images = links.pluck(0).select(&:image?)
          'yes' if images.any?
        end

        def view_issues_edit_notes_bottom_style(context = {})
          if ((User.current.pref.dmsf_attachments_upload_choice == 'Attachments') ||
            !allowed_to_attach_documents(context[:container])) && allowed_to_attach_attachments(context[:container])
            ''
          else
            'display: none'
          end
        end

        private

        def allowed_to_attach_documents(container)
          container.respond_to?(:saved_dmsf_attachments) && container.project &&
            User.current.allowed_to?(:file_manipulation, container.project) &&
            Setting.plugin_redmine_dmsf['dmsf_act_as_attachable'] &&
            (container.project&.dmsf_act_as_attachable == Project::ATTACHABLE_DMS_AND_ATTACHMENTS)
        end

        def allowed_to_attach_attachments(container)
          return true unless defined?(EasyExtensions)

          !(allowed_to_attach_documents(container) && !container.project.module_enabled?(:documents))
        end

        def get_links(container)
          links = []
          if defined?(container.dmsf_files) &&
             User.current.allowed_to?(:view_dmsf_files, container.project) &&
             Setting.plugin_redmine_dmsf['dmsf_act_as_attachable'] &&
             container.project.dmsf_act_as_attachable == Project::ATTACHABLE_DMS_AND_ATTACHMENTS
            container.dmsf_files.each do |dmsf_file|
              links << [dmsf_file, nil, dmsf_file.created_at] if dmsf_file.last_revision
            end
            container.dmsf_links.each do |dmsf_link|
              dmsf_file = dmsf_link.target_file
              links << [dmsf_file, dmsf_link, dmsf_link.created_at] if dmsf_file&.last_revision
            end
            # Sort by 'create_at'
            links.sort_by! { |a| a[2] }
          end
          links
        end

        def show_thumbnails(container, controller)
          links = get_links(container)
          return if links.blank?

          controller.send :render_to_string, { partial: 'dmsf_files/thumbnails',
                                               locals: { links: links,
                                                         thumbnails: Setting.thumbnails_enabled?,
                                                         link_to: false } }
        end

        def attach_documents_form(context, label: true, description: true)
          return unless context.is_a?(Hash) && context[:container]

          # Add Dmsf upload form
          container = context[:container]
          return unless allowed_to_attach_documents(container)

          html = description ? +'<p' : +'<div'
          if User.current.pref.dmsf_attachments_upload_choice == 'Attachments' &&
             allowed_to_attach_attachments(container)
            html << ' style="display: none;"'
          end
          html << '>'
          if label
            html << "<label>#{l(:label_document_plural)}</label>"
            html << '<span class="attachments-container dmsf-uploader">'
          else
            html << %(<span class="attachments-container dmsf-uploader"
              style="border: 2px dashed #dfccaf; background: none;">)
          end
          html << context[:controller].send(:render_to_string, { partial: 'dmsf_upload/form',
                                                                 locals: { container: container,
                                                                           multiple: true,
                                                                           description: description,
                                                                           awf: false } })
          html << '</span>'
          html << (description ? '</p>' : '</div>')
          html
        end

        def show_attached_documents(container, controller, _attachments = nil)
          # Add list of attached documents
          links = get_links(container)
          return if links.blank?

          if defined?(EasyExtensions)
            attachment_rows(links, container, controller)
          else
            controller.send :render_to_string,
                            { partial: 'dmsf_files/links',
                              locals: { links: links, thumbnails: Setting.thumbnails_enabled? } }
          end
        end

        def attachment_rows(links, issue, controller)
          return unless links.any?

          html = +"<tbody><tr><th colspan=\"4\">#{l(:label_dmsf_attachments)} (#{links.count})</th></tr>"
          links.each do |dmsf_file, link, _created_at|
            html << attachment_row(dmsf_file, link, issue, controller)
          end
          html << '</tbody>'
          html
        end

        def attachment_row(dmsf_file, link, issue, controller)
          html = link ? +'<tr class="dmsf-gray">' : +'<tr>'
          # Checkbox
          show_checkboxes = true # options[:show_checkboxes].nil? ? true : options[:show_checkboxes]
          html << '<td></td>' if show_checkboxes
          file_view_url = url_for({ controller: :dmsf_files, action: 'view', id: dmsf_file })
          # Title, size
          html << '<td>'
          data = "#{dmsf_file.last_revision.detect_content_type}:#{h(dmsf_file.name)}:#{file_view_url}"
          html << link_to(h(dmsf_file.title), file_view_url,
                          target: '_blank',
                          rel: 'noopener',
                          class: "icon icon-file #{DmsfHelper.filetype_css(dmsf_file.name)}",
                          title: h(dmsf_file.last_revision.try(:tooltip)),
                          'data-downloadurl' => data)
          html << "<span class=\"size\">(#{number_to_human_size(dmsf_file.last_revision.size)})</span>"
          html << " - #{h(dmsf_file.description)}" if dmsf_file.description.present?
          html << '</td>'
          # Author, updated at
          html << '<td>'
          author = "#{h(dmsf_file.last_revision.user)}, #{format_time(dmsf_file.last_revision.updated_at)}"
          html << "<span class=\"author\">#{author}</span>"
          html << '</td>'
          # Command icons
          html << '<td class="fast-icons easy-query-additional-ending-buttons hide-when-print">'
          # Details
          html << if User.current.allowed_to? :file_manipulation, dmsf_file.project
                    link_to '', dmsf_file_path(id: dmsf_file),
                            title: l(:link_details, title: h(dmsf_file.last_revision.title)),
                            class: 'icon icon-edit'
                  else
                    '<span class="icon"></span>'
                  end
          # Email
          html << link_to('', entries_operations_dmsf_path(id: dmsf_file.project,
                                                           email_entries: 'email',
                                                           files: [dmsf_file.id]),
                          method: :post,
                          title: l(:heading_send_documents_by_email), class: 'icon icon-email-disabled')
          # Lock
          html << if !dmsf_file.locked?
                    link_to '', lock_dmsf_files_path(id: dmsf_file),
                            title: l(:title_lock_file),
                            class: 'icon icon-lock'
                  elsif dmsf_file.unlockable? && (!dmsf_file.locked_for_user? ||
                    User.current.allowed_to?(:force_file_unlock, dmsf_file.project))
                    link_to '', unlock_dmsf_files_path(id: dmsf_file),
                            title: dmsf_file.locked_title, class: 'icon icon-unlock'
                  else
                    "<span class=\"icon icon-unlock\" title=\"#{dmsf_file.locked_title}\"></span>"
                  end
          if dmsf_file.locked?
            html << ('<span class="icon"></span>' * 2)
          else
            # Notifications
            html << if dmsf_file.notification
                      link_to '', notify_deactivate_dmsf_files_path(id: dmsf_file),
                              title: l(:title_notifications_active_deactivate), class: 'icon icon-email'
                    else
                      link_to '', notify_activate_dmsf_files_path(id: dmsf_file),
                              title: l(:title_notifications_not_active_activate), class: 'icon icon-email-add'
                    end
            # Delete
            if issue.attributes_editable? && ((link && User.current.allowed_to?(:file_manipulation,
                                                                                dmsf_file.project)) || (!link &&
              User.current.allowed_to?(:file_delete, dmsf_file.project)))
              url = if link
                      dmsf_link_path link, commit: 'yes', back_url: issue_path(issue)
                    else
                      dmsf_file_path id: dmsf_file, commit: 'yes', back_url: issue_path(issue)
                    end
              html << link_to('',
                              url,
                              data: { confirm: l(:text_are_you_sure) },
                              method: :delete,
                              title: l(:button_delete),
                              class: 'icon icon-del')
            end
          end
          # Approval workflow
          if dmsf_file.last_revision.dmsf_workflow_id
            wf = DmsfWorkflow.find_by(id: dmsf_file.last_revision.dmsf_workflow_id)
          end
          html << controller.send(:render_to_string,
                                  { partial: 'dmsf_workflows/approval_workflow_button',
                                    locals: {
                                      file: dmsf_file,
                                      file_approval_allowed: User.current.allowed_to?(:file_approval,
                                                                                      dmsf_file.project),
                                      workflows_available: DmsfWorkflow.exists?(['project_id = ? OR project_id IS NULL',
                                                                                 dmsf_file.project.id]),
                                      project: dmsf_file.project,
                                      wf: wf,
                                      dmsf_link_id: nil
                                    } })
          html << '</td>'
          html << '</tr>'
          html
        end
      end
    end
  end
end
