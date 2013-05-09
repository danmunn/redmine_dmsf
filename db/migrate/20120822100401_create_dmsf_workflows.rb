class CreateDmsfWorkflows < ActiveRecord::Migration
  def self.up
    create_table :dmsf_workflows do |t|
      t.string :name, :null => false
      t.references :project    
    end
    add_index :dmsf_workflows, [:name], :unique => true
  end
  
  def self.down
    drop_table :dmsf_workflows
  end    
end
