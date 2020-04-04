class AddNewMtaIdToFeeds < ActiveRecord::Migration[5.2]
  def up
    rename_column :realtime_feeds, :mta_id, :old_mta_id
    add_column :realtime_feeds, :mta_id, :string

    execute <<-SQL
      UPDATE realtime_feeds
      SET mta_id = CASE
        WHEN old_mta_id = 1 THEN 'gtfs'
        WHEN old_mta_id = 2 THEN 'gtfs-l'
        WHEN old_mta_id = 11 THEN 'gtfs-si'
        WHEN old_mta_id = 16 THEN 'gtfs-nqrw'
        WHEN old_mta_id = 21 THEN 'gtfs-bdfm'
        WHEN old_mta_id = 26 THEN 'gtfs-ace'
        WHEN old_mta_id = 31 THEN 'gtfs-g'
        WHEN old_mta_id = 36 THEN 'gtfs-jz'
        WHEN old_mta_id = 51 THEN 'gtfs-7'
      END
    SQL

    change_column :realtime_feeds, :mta_id, :string, null: false
    add_index :realtime_feeds, :mta_id, unique: true
  end

  def down
    remove_column :realtime_feeds, :mta_id
    rename_column :realtime_feeds, :old_mta_id, :mta_id
  end
end
