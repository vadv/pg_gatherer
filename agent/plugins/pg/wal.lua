local time = require("time")
local plugin = 'pg.wal'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.agent
local manager = helpers.connections.manager
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end

local function collect()
  local result, err = agent:query("select wal_position, pg_is_in_recovery, time_lag from gatherer.pg_wal_position()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local wal_position, pg_is_in_recovery, time_lag = row[1], row[2], row[3]
    local wal_speed = helpers.metric.speed(plugin..".speed", wal_position)

    if wal_speed then metric_insert(plugin..".speed", nil, nil, wal_speed, nil) end
    if pg_is_in_recovery then metric_insert(plugin..".replication_time_lag", nil, nil, time_lag, nil) end

  end
end

-- run collect
helpers.runner.run_every(collect, 60)
