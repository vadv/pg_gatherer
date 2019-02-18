local json = require('json')
local crypto = require('crypto')
local inspect = require('inspect')
local plugin = 'pg.statements'

local function main(agent, manager)
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_statements()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local key = crypto.md5(plugin..tostring(jsonb.queryid)..tostring(jsonb.query)..tostring(jsonb.dbname)..tostring(jsonb.user))
    jsonb.total_time = counter_speed(key..".total_time", jsonb.total_time)
    jsonb.rows = counter_diff(key..".rows", jsonb.rows)
    jsonb.calls = counter_diff(key..".calls", jsonb.calls)
    jsonb.total_time = counter_diff(key..".total_time", jsonb.total_time)
    jsonb.shared_blks_hit = counter_diff(key..".shared_blks_hit", jsonb.shared_blks_hit)
    jsonb.shared_blks_read = counter_diff(key..".shared_blks_read", jsonb.shared_blks_read)
    jsonb.shared_blks_dirtied = counter_diff(key..".shared_blks_dirtied", jsonb.shared_blks_dirtied)
    jsonb.shared_blks_written = counter_diff(key..".shared_blks_written", jsonb.shared_blks_written)
    jsonb.local_blks_hit = counter_diff(key..".local_blks_hit", jsonb.local_blks_hit)
    jsonb.local_blks_read = counter_diff(key..".local_blks_read", jsonb.local_blks_read)
    jsonb.local_blks_dirtied = counter_diff(key..".local_blks_dirtied", jsonb.local_blks_dirtied)
    jsonb.local_blks_written = counter_diff(key..".local_blks_written", jsonb.local_blks_written)
    jsonb.temp_blks_read = counter_diff(key..".temp_blks_read", jsonb.temp_blks_read)
    jsonb.temp_blks_written = counter_diff(key..".temp_blks_written", jsonb.temp_blks_written)
    jsonb.blk_read_time = counter_speed(key..".blk_read_time", jsonb.blk_read_time)
    jsonb.blk_write_time = counter_speed(key..".blk_write_time", jsonb.blk_write_time)

    if jsonb.calls and (jsonb.calls > 0) then
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      insert_metric(host, plugin, row[1], nil, nil, jsonb, manager)
    end

  end
end

return main
