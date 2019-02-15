local json = require('json')
local plugin = 'pg.databases'

local function main(agent, manager)
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_databases()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local database = jsonb.datname
    jsonb.xact_commit = counter_speed(database..".xact_commit", jsonb.xact_commit)
    jsonb.xact_rollback = counter_speed(database..".xact_rollback", jsonb.xact_rollback)
    jsonb.blks_read = counter_speed(database..".blks_read", jsonb.blks_read)
    jsonb.blks_hit = counter_speed(database..".blks_hit", jsonb.blks_hit)
    jsonb.tup_returned = counter_speed(database..".tup_returned", jsonb.tup_returned)
    jsonb.tup_fetched = counter_speed(database..".tup_fetched", jsonb.tup_fetched)
    jsonb.tup_inserted = counter_speed(database..".tup_inserted", jsonb.tup_inserted)
    jsonb.tup_updated = counter_speed(database..".tup_updated", jsonb.tup_updated)
    jsonb.tup_deleted = counter_speed(database..".tup_deleted", jsonb.tup_deleted)
    jsonb.conflicts = counter_speed(database..".conflicts", jsonb.conflicts)
    jsonb.temp_files = counter_diff(database..".temp_files", jsonb.temp_files)
    jsonb.temp_bytes = counter_speed(database..".temp_bytes", jsonb.temp_bytes)
    jsonb.deadlocks = counter_speed(database..".deadlocks", jsonb.deadlocks)
    jsonb.blk_read_time = counter_diff(database..".blk_read_time", jsonb.blk_read_time)
    jsonb.blk_write_time = counter_diff(database..".blk_write_time", jsonb.blk_write_time)

    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    insert_metric(host, plugin, row[1], nil, nil, jsonb, manager)
  end
end

return main
