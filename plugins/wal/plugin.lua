local plugin          = 'pg.wal'
local every           = 60

local current_dir     = filepath.join(root, "wal")

local function get_sql()
  local filename = ""
  if get_pg_is_in_recovery() then
    -- slave
    if get_pg_server_version() >= 10 then
      filename = filepath.join(current_dir, "wal_slave_10.sql")
    else
      filename = filepath.join(current_dir, "wal_slave_9.sql")
    end
  else
    -- master
    if get_pg_server_version() >= 10 then
      filename = filepath.join(current_dir, "wal_master_10.sql")
    else
      filename = filepath.join(current_dir, "wal_master_10.sql")
    end
  end
  local sql, err = ioutil.read_file(filename)
  if err then error(err) end
  return sql
end

local function collect()
  local result = agent:query(get_sql())
  for _, row in pairs(result.rows) do
    local wal_position, pg_is_in_recovery, time_lag = row[1], row[2], row[3]
    local wal_speed = cache:speed_and_set("wal_speed", wal_position)
    if wal_speed then
      manager:send_metric({plugin=plugin..".speed", float=wal_speed})
    end
    if pg_is_in_recovery then
      manager:send_metric({plugin=plugin..".replication_time_lag", float=time_lag})
    end
  end
end

run_every(collect, every)
