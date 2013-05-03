class CreateDmsfWorkflowStepAssignments < ActiveRecord::Migration
  def self.up
    create_table :dmsf_workflow_step_assignments do |t|
      t.references :workflow_step, :null => false
      t.references :user, :null => false
      t.references :entity, :null => false
    end   
    add_index :dmsf_workflow_step_assignments, 
      [:workflow_step_id, :entity_id],
      # The default index name exceeds the index name limit
      {:name => 'index_dmsf_wrkfl_step_assigns_on_wrkfl_step_id_and_entity_id'}
  end
  
  def self.down
    drop_table :dmsf_workflow_step_assignments
  end
end