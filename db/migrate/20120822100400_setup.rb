class Setup < ActiveRecord::Migration
  def self.up
    #DmsfEntity
    create_table :dmsf_entities do |t|
      #Required for awesome_nested_set
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt
      t.integer :depth

      # Entity information
      t.boolean :collection, :null => false
      t.string :title, :null => false
      t.string :description
      t.boolean :deleted, :null => false
      t.boolean :notification, :default => 0, :null => false
      t.references :deleted_by # Will reference a User
      t.references :owner, :null => false # Will reference a User
      t.references :project, :null => false # Will reference a Project
      t.timestamps
    end
  end

  def self.down
    drop_table :dmsf_entities
  end
end