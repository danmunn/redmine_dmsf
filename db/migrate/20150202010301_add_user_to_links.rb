class AddUserToLinks < ActiveRecord::Migration
  def up
    add_column :dmsf_links, :user_id, :integer
  end

  def down
    remove_column :dmsf_links, :user_id
  end
end
