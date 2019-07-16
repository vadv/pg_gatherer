local plugin = 'pg.block'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(key, snapshot, value_bigint, value_double, value_jsonb, helpers.manager)
end

local function collect()
  local agent = helpers.agent()
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_block()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    metric_insert(plugin, row[1], nil, nil, row[2])
  end
end

-- run collect
helpers.runner.run_every(collect, 30)
