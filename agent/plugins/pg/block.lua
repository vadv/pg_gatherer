local time = require('time')
local plugin = 'pg.block'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.get_agent_connection()
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end
local db_list = helpers.connections.get_databases(helpers.connections.manager, helpers.host)

local function collect_for_db(dbname)
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_block()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin, row[1], nil, nil, row[2])
  end
end

local function collect()
  for _, db in pairs(db_list) do collect_for_db(db) end
end

-- run collect
helpers.runner.run_every(collect, 5)
