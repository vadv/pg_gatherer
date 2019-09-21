local plugin             = 'pg.databases'
local every              = 60

local current_dir        = filepath.join(root, "databases")
local sql_databases, err = ioutil.read_file(filepath.join(current_dir, "databases.sql"))
if err then error(err) end

local function collect()
  local result = connection:query(sql_databases, 60)
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end
    local database       = jsonb.datname
    jsonb.xact_commit    = cache:speed_and_set(database .. ".xact_commit", jsonb.xact_commit)
    jsonb.xact_rollback  = cache:speed_and_set(database .. ".xact_rollback", jsonb.xact_rollback)
    jsonb.blks_read      = cache:speed_and_set(database .. ".blks_read", jsonb.blks_read)
    jsonb.blks_hit       = cache:speed_and_set(database .. ".blks_hit", jsonb.blks_hit)
    jsonb.tup_returned   = cache:speed_and_set(database .. ".tup_returned", jsonb.tup_returned)
    jsonb.tup_fetched    = cache:speed_and_set(database .. ".tup_fetched", jsonb.tup_fetched)
    jsonb.tup_inserted   = cache:speed_and_set(database .. ".tup_inserted", jsonb.tup_inserted)
    jsonb.tup_updated    = cache:speed_and_set(database .. ".tup_updated", jsonb.tup_updated)
    jsonb.tup_deleted    = cache:speed_and_set(database .. ".tup_deleted", jsonb.tup_deleted)
    jsonb.conflicts      = cache:speed_and_set(database .. ".conflicts", jsonb.conflicts)
    jsonb.temp_files     = cache:diff_and_set(database .. ".temp_files", jsonb.temp_files)
    jsonb.temp_bytes     = cache:speed_and_set(database .. ".temp_bytes", jsonb.temp_bytes)
    jsonb.deadlocks      = cache:speed_and_set(database .. ".deadlocks", jsonb.deadlocks)
    jsonb.blk_read_time  = cache:diff_and_set(database .. ".blk_read_time", jsonb.blk_read_time)
    jsonb.blk_write_time = cache:diff_and_set(database .. ".blk_write_time", jsonb.blk_write_time)

    local jsonb, err     = json.encode(jsonb)
    if err then error(err) end
    manager:send_metric({ plugin = plugin, snapshot = row[1], json = jsonb })
  end
end

run_every(collect, every)
