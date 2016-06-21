class AddEditableToFolder < ActiveRecord::Migration
  def change
    add_column :dmsf_folders, :editable, :boolean
  end
end
