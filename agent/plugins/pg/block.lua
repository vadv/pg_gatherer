local time = require('time')
local plugin = 'pg.block'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.agent
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end

local function collect()
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_block()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin, row[1], nil, nil, row[2])
  end
end

-- supervisor
while true do
  collect()
  time.sleep(1)
end
