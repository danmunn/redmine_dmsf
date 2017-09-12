module DmsfFolderPermissionsHelper

  def users_checkboxes(users)
    s = ''
    if users
      users.each do |user|
        content = check_box_tag('permissions[user_ids][]', user.id, true, :id => nil) + user.name
        s << content_tag(:label, content, :id => "user_permission_ids_#{user.id}", :class => 'inline')
      end
    end
    s.html_safe
  end

  def render_principals_for_new_folder_permissions(users)
    principals_check_box_tags 'user_ids[]', users
  end

end
