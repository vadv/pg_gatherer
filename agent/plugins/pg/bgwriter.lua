local json = require('json')
local time = require('time')
local plugin = 'pg.bgwriter'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.agent
local manager = helpers.connections.manager
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end

local function collect()
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_bgwriter()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    jsonb.checkpoints_timed = helpers.metric.diff("checkpoints_timed", jsonb.checkpoints_timed)
    jsonb.checkpoints_req = helpers.metric.diff("checkpoints_req", jsonb.checkpoints_req)

    jsonb.checkpoint_write_time = helpers.metric.diff("checkpoint_write_time", jsonb.checkpoint_write_time)
    jsonb.checkpoint_sync_time = helpers.metric.diff("checkpoint_sync_time", jsonb.checkpoint_sync_time)

    jsonb.maxwritten_clean = helpers.metric.diff("maxwritten_clean", jsonb.maxwritten_clean)

    jsonb.buffers_backend_fsync = helpers.metric.diff("buffers_backend_fsync", jsonb.buffers_backend_fsync)
    jsonb.buffers_alloc = helpers.metric.diff("buffers_alloc", jsonb.buffers_alloc)

    jsonb.buffers_checkpoint = helpers.metric.speed("buffers_checkpoint", jsonb.buffers_checkpoint)
    jsonb.buffers_clean = helpers.metric.speed("buffers_clean", jsonb.buffers_clean)
    jsonb.buffers_backend = helpers.metric.speed("buffers_backend", jsonb.buffers_backend)

    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    metric_insert(plugin, row[1], nil, nil, jsonb)
  end
end

-- supervisor
while true do
  collect()
  time.sleep(30)
end
