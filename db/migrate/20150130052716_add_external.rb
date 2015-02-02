class AddExternal < ActiveRecord::Migration
  def up
    change_column :dmsf_links, :target_id, :integer, :null => true

    add_column :dmsf_links, :external_url, :string, :null => true
    add_column :dmsf_links, :user_id, :integer
  end

  def down
    change_column :dmsf_links, :target_id, :integer, :null => false

    remove_column :dmsf_links, :external_url
    remove_column :dmsf_links, :user_id
  end
end
