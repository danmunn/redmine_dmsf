class CreateDmsfWorkflowStepActions < ActiveRecord::Migration
  def self.up
    create_table :dmsf_workflow_step_actions do |t|
      t.references :workflow_step_assignment, :null => false
      t.integer :action, :null => false
      t.text :note      
      t.timestamp :created_at
    end
    add_index :dmsf_workflow_step_actions, 
      :workflow_step_assignment_id,
      # The default index name exceeds the index name limit
      {:name => 'index_dmsf_workflow_step_actions_on_workflow_step_assignment_id'}
  end
  def self.down
    drop_table :dmsf_workflow_step_actions
  end
end
