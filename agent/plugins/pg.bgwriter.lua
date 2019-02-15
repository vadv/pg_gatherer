local json = require('json')
local plugin = 'pg.bgwriter'

local function main(agent, manager)
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_bgwriter()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    jsonb.checkpoints_timed = counter_diff("checkpoints_timed", jsonb.checkpoints_timed)
    jsonb.checkpoints_req = counter_diff("checkpoints_req", jsonb.checkpoints_req)

    jsonb.checkpoint_write_time = counter_diff("checkpoint_write_time", jsonb.checkpoint_write_time)
    jsonb.checkpoint_sync_time = counter_diff("checkpoint_sync_time", jsonb.checkpoint_sync_time)

    jsonb.maxwritten_clean = counter_diff("maxwritten_clean", jsonb.maxwritten_clean)

    jsonb.buffers_backend_fsync = counter_diff("buffers_backend_fsync", jsonb.buffers_backend_fsync)
    jsonb.buffers_alloc = counter_diff("buffers_alloc", jsonb.buffers_alloc)

    jsonb.buffers_checkpoint = counter_speed("buffers_checkpoint", jsonb.buffers_checkpoint)
    jsonb.buffers_clean = counter_speed("buffers_clean", jsonb.buffers_clean)
    jsonb.buffers_backend = counter_speed("buffers_backend", jsonb.buffers_backend)

    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    insert_metric(host, plugin, row[1], nil, nil, jsonb, manager)
  end
end

return main
