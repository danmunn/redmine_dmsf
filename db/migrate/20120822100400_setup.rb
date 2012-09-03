class Setup < ActiveRecord::Migration
  class DmsfFile < ActiveRecord::Base
    #Definition as model no-longer exists
  end

  def self.up

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
    add_column :dmsf_folders, :deleted, :boolean

    rename_table :dmsf_folders, :dmsf_entities
    add_index :dmsf_entities, :type

    Dmsf::Entity.reset_column_information

    Dmsf::Entity.all.each do |e|
      e.update_column :type, 'Dmsf::Folder' #Each entity is a DMSF Folder
    end

    DmsfFile.all.each do |f|
      new_entity = Dmsf::File.new :parent_id      => f.dmsf_folder_id,
                                  :notification   => f.notification,
                                  :deleted        => f.deleted,
                                  :deleted_by_id  => f.deleted_by_user_id
      new_entity.save!
    end

    drop_table :dmsf_files;

  end

  def self.down
    #For now we lie, because I've not worked out how we migrate things back yet
    raise ActiveRecord::IrreversibleMigration, "Redmine DMSF 1.5.0 structures are not downgradable"
  end

end