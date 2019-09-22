local plugin_name = 'pg.wal'
local every       = 60

local function get_sql()
  local filename = ""
  if get_pg_is_in_recovery() then
    -- slave
    if get_pg_server_version() >= 10 then
      filename = "wal_slave_10.sql"
    else
      filename = "wal_slave_9.sql"
    end
  else
    -- master
    if get_pg_server_version() >= 10 then
      filename = "wal_master_10.sql"
    else
      filename = "wal_master_10.sql"
    end
  end
  return read_file_in_current_dir(filename)
end

local function collect()
  local result = target:query(get_sql())
  for _, row in pairs(result.rows) do
    local wal_position, pg_is_in_recovery, time_lag = row[1], row[2], row[3]
    local wal_speed                                 = cache:speed_and_set("wal_speed", wal_position)
    if wal_speed then
      storage_insert_metric({ plugin = plugin_name .. ".speed", float = wal_speed })
    end
    if pg_is_in_recovery then
      storage_insert_metric({ plugin = plugin_name .. ".replication_time_lag", float = time_lag })
    end
  end
end

run_every(collect, every)
