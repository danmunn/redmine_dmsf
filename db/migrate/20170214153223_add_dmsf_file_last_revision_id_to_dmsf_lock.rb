class AddDmsfFileLastRevisionIdToDmsfLock < ActiveRecord::Migration
  def change
    rename_column :dmsf_locks, :revision, :dmsf_file_last_revision_id
  end
end
