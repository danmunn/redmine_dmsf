class CreateHierarchy < ActiveRecord::Migration
  def self.up
    create_table :dmsf_folders do |t|
      t.string :name, :null => false
      t.text :description
      t.references :project, :null => false
      t.references :dmsf_folder
      
      t.boolean :notification, :default => false, :null => false
      
      t.references :user, :null => false
      t.timestamps
    end
    
    create_table :dmsf_files do |t|
      t.string :name, :null => false
      t.references :project, :null => false
      t.references :dmsf_folder

      t.boolean :notification, :default => false, :null => false
      
      t.boolean :deleted, :default => false, :null => false
      t.integer :deleted_by_user_id
      
      t.timestamps
    end
    
    create_table :dmsf_file_revisions do |t|
      t.references :dmsf_file, :null => false
      t.string :disk_filename, :null => false
      
      t.string :name, :null => false
      t.references :dmsf_folder
      
      t.integer :size
      t.string :mime_type
      t.string :title
      t.text :description
      t.references :user, :null => false
      
      t.integer :workflow
      
      t.text :comment
      t.integer :major_version, :null => false
      t.integer :minor_version, :null => false

      t.integer :source_dmsf_file_revision_id
      
      t.boolean :deleted, :default => false, :null => false
      t.integer :deleted_by_user_id
      
      t.timestamps
    end
    
    create_table :dmsf_file_locks do |t|
      t.references :dmsf_file, :null => false
      t.boolean :locked, :default => false, :null => false
      t.references :user, :null => false
      t.timestamps
    end
    
    create_table :dmsf_user_prefs do |t|
      t.references :project, :null => false
      t.references :user, :null => false
      
      t.boolean :email_notify
      
      t.timestamps
    end
    
  end

  def self.down
    drop_table :dmsf_file_revisions
    drop_table :dmsf_files
    drop_table :dmsf_folders
  end
end
