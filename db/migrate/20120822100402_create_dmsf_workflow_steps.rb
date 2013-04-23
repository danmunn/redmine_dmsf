class CreateDmsfWorkflowSteps < ActiveRecord::Migration
  def self.up
    create_table :dmsf_workflow_steps do |t|
      t.references :workflow, :null => false
      t.integer :step, :null => false
      t.references :user, :null => false
      t.integer :operator, :null => false
    end
    add_index :dmsf_workflow_steps, :workflow_id
    add_index :dmsf_workflow_steps, [:workflow_id, :user_id, :step], :unique => true
  end
  
  def self.down
    drop_table :dmsf_workflow_steps
  end
end
