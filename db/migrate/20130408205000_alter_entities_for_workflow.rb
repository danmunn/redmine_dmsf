class AlterEntitiesForWorkflow < ActiveRecord::Migration

  def self.up
    #Things to do:
    # 1: dmsf_file_revisions needs to not have a workflow, but instead a completion flag
    # 2: We need storage for a workflow id against an entity (dmsf_entities)
    rename_column :dmsf_revisions, :workflow_id, :workflow_completed
    change_column :dmsf_revisions, :workflow_completed, :boolean, :default => false, :null => false
    Dmsf::Revision.update_all(:workflow_completed => :true)
    add_column :dmsf_entities, :workflow_id, :integer, :null => false, :default => -1
  end

  def self.down
    rename_column :dmsf_revisions, :workflow_completed, :workflow_id
    change_column :dmsf_revisions, :workflow_id, :integer, :default => 0, :null => false
    Dmsf::Revision.update_all(:workflow_id => 0)
    remove_column :dmsf_entities, :workflow_id
  end

end