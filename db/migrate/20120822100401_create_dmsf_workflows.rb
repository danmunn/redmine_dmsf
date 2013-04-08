class CreateDmsfWorkflows < ActiveRecord::Migration
  def self.up
    create_table :dmsf_workflows do |t|
      t.string :name, :null => false
      t.references :project    
    end
    add_index :dmsf_workflows, [:name], :unique => true
    add_column :dmsf_entities, :dmsf_workflow_id, :integer
  end
  
  def self.down
    drop_table :dmsf_workflows
    remove_column :dmsf_entities, :dmsf_workflow_id
  end    
end
