class AddRevisionToDmsfLock < ActiveRecord::Migration
  def change
    add_column :dmsf_locks, :revision, :integer
  end
end
