local time = require('time')
local plugin = 'pg.healthcheck'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.agent

local function collect()
  local result, err = agent:query("select gatherer.snapshot_id(10)")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin, row[1], nil, nil, nil)
  end
end

-- run collect
helpers.runner.run_every(collect, 60)
