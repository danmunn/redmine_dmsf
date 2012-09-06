class Setup < ActiveRecord::Migration
  class DmsfFile < ActiveRecord::Base
    #Definition as model no-longer exists
  end

  def self.up
    self.alter_dmsf_revisions
    self.alter_dmsf_entities
    self.remove_dmsf_files
  end

  def self.down
    #For now we lie, because I've not worked out how we migrate things back yet
    raise ActiveRecord::IrreversibleMigration, "Redmine DMSF 1.5.0 structures are not downgradable"
  end

  protected
  def self.alter_dmsf_entities
    #Things to do:
    # 1: Adapt dmsf_folders to structures for dmsf_entities
    # 2: Convert data from dmsf_folders where appropriate (setting Type etc)
    # 3: Load dmsf_files into dmsf_entities
    # 4: Drop dmsf_files and rename dmsf_folders (to dmsf_entities)

    rename_column :dmsf_folders, :dmsf_folder_id, :parent_id
    rename_column :dmsf_folders, :user_id, :owner_id
    add_column :dmsf_folders, :lft, :integer
    add_column :dmsf_folders, :rgt, :integer
    add_column :dmsf_folders, :depth, :integer
    add_column :dmsf_folders, :type, :string
    add_column :dmsf_folders, :deleted_by_id, :integer
    #Ensure we force true/false values
    add_column :dmsf_folders, :deleted, :boolean, {:null => false, :default => false}

    rename_table :dmsf_folders, :dmsf_entities

    #Entity type (Dmsf::Folder etc), lft value (nested set), and title
    #should all be indexed to allow best-performance
    add_index :dmsf_entities, :type
    add_index :dmsf_entities, :lft
    add_index :dmsf_entities, :title

    Dmsf::Entity.reset_column_information

    Dmsf::Entity.all.each do |e|
      e.update_column :type, 'Dmsf::Folder' #Each entity is a DMSF Folder
    end
  end

  def self.alter_dmsf_revisions
    rename_column :dmsf_file_revisions, :deleted_by_user_id, :deleted_by_id
    rename_column :dmsf_file_revisions, :disk_filename, :source_path
    rename_column :dmsf_file_revisions, :source_dmsf_file_revision_id, :source_revision_id
    rename_column :dmsf_file_revisions, :user_id, :owner_id
    rename_column :dmsf_file_revisions, :workflow, :workflow_id
    rename_column :dmsf_file_revisions, :dmsf_file_id, :file_id

    remove_column :dmsf_file_revisions, :dmsf_folder_id
    remove_column :dmsf_file_revisions, :title
    rename_column :dmsf_file_revisions, :name, :title

    rename_table :dmsf_file_revisions, :dmsf_revisions
  end

  def self.remove_dmsf_files
    DmsfFile.all.each do |f|
      new_entity = Dmsf::File.create! :parent_id      => f.dmsf_folder_id,
                                      :notification   => f.notification,
                                      :deleted        => f.deleted,
                                      :deleted_by_id  => f.deleted_by_user_id

      Dmsf::Revision.where(:file_id => f.id).update_all(:file_id => new_entity.id)
    end

    drop_table :dmsf_files;

  end

end