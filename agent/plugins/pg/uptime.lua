local time = require('time')
local plugin = 'pg.uptime'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.agent()
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(key, snapshot, value_bigint, value_double, value_jsonb, helpers.manager)
end

local function collect()
  local result, err = agent:query("select gatherer.uptime()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin, nil, row[1], nil, nil)
  end
  local result, err = agent:query("select gatherer.checkpointer_uptime()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin..".checkpointer", nil, row[1], nil, nil)
  end
end

-- run collect
helpers.runner.run_every(collect, 360)
