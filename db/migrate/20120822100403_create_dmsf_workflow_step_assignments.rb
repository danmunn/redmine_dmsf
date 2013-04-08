class CreateDmsfWorkflowStepAssignments < ActiveRecord::Migration
  def self.up
    create_table :dmsf_workflow_step_assignments do |t|
      t.references :dmsf_workflow_step, :null => false
      t.references :user, :null => false
      t.references :dmsf_revision, :null => false
    end   
    add_index :dmsf_workflow_step_assignments, 
      [:dmsf_workflow_step_id, :dmsf_revision_id], 
      # The default index name exceeds the index name limit
      {:name => 'index_dmsf_wrkfl_step_assigns_on_wrkfl_step_id_and_revision_id'}
  end
  
  def self.down
    drop_table :dmsf_workflow_step_assignments
  end
end