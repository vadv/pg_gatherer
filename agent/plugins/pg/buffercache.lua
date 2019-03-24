local plugin = 'pg.buffercache'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(key, snapshot, value_bigint, value_double, value_jsonb, helpers.manager)
end

local snapshot = nil

local function collect_for_db(connection_string)
  local agent = helpers.agent(connection_string)
  local result, err = agent:query("select gatherer.snapshot_id(300), * from gatherer.pg_buffer_cache_uses()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    if not snapshot then snapshot = row[1] end
    metric_insert(plugin, snapshot, nil, nil, row[2])
  end
end

local function collect()
  collect_for_db()
  for _, str in pairs(helpers.get_additional_agent_connections()) do collect_for_db(str) end
  snapshot = nil
end

-- run collect
helpers.runner.run_every(collect, 300)
