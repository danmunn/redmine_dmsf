class CreateDmsfWorkflowSteps < ActiveRecord::Migration
  def self.up
    create_table :dmsf_workflow_steps do |t|
      t.references :workflow, :null => false
      t.integer :step, :null => false
      t.references :user, :null => false
      t.integer :operator, :null => false
    end
    add_index :dmsf_workflow_steps, :workflow_id
  end
  
  def self.down
    drop_table :dmsf_workflow_steps
  end
end
