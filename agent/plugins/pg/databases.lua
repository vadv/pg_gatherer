local json = require('json')
local plugin = 'pg.databases'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.agent()
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(key, snapshot, value_bigint, value_double, value_jsonb, helpers.manager)
end

local function collect()
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_databases()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local database = jsonb.datname
    jsonb.xact_commit = helpers.metric.speed(database..".xact_commit", jsonb.xact_commit)
    jsonb.xact_rollback = helpers.metric.speed(database..".xact_rollback", jsonb.xact_rollback)
    jsonb.blks_read = helpers.metric.speed(database..".blks_read", jsonb.blks_read)
    jsonb.blks_hit = helpers.metric.speed(database..".blks_hit", jsonb.blks_hit)
    jsonb.tup_returned = helpers.metric.speed(database..".tup_returned", jsonb.tup_returned)
    jsonb.tup_fetched = helpers.metric.speed(database..".tup_fetched", jsonb.tup_fetched)
    jsonb.tup_inserted = helpers.metric.speed(database..".tup_inserted", jsonb.tup_inserted)
    jsonb.tup_updated = helpers.metric.speed(database..".tup_updated", jsonb.tup_updated)
    jsonb.tup_deleted = helpers.metric.speed(database..".tup_deleted", jsonb.tup_deleted)
    jsonb.conflicts = helpers.metric.speed(database..".conflicts", jsonb.conflicts)
    jsonb.temp_files = helpers.metric.diff(database..".temp_files", jsonb.temp_files)
    jsonb.temp_bytes = helpers.metric.speed(database..".temp_bytes", jsonb.temp_bytes)
    jsonb.deadlocks = helpers.metric.speed(database..".deadlocks", jsonb.deadlocks)
    jsonb.blk_read_time = helpers.metric.diff(database..".blk_read_time", jsonb.blk_read_time)
    jsonb.blk_write_time = helpers.metric.diff(database..".blk_write_time", jsonb.blk_write_time)

    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    metric_insert(plugin, row[1], nil, nil, jsonb)
  end
end

-- run collect
helpers.runner.run_every(collect, 60)
