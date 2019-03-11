local time = require("time")
local json = require("json")
local plugin = 'pg.replication_slots'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.agent
local manager = helpers.connections.manager
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end

local function collect()
  local result, err = agent:query("select slot_name, size from gatherer.pg_replication_slots()")
  if err then error(err) end
  local jsonb = {}
  for _, row in pairs(result.rows) do
    jsonb[ row[1] ] = tonumber(row[2])
  end
  local jsonb, err = json.encode(jsonb)
  if err then error(err) end
  metric_insert(plugin, nil, nil, nil, jsonb)
end

-- run collect
helpers.runner.run_every(collect, 60)
