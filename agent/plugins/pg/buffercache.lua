local json = require('json')
local time = require('time')
local plugin = 'pg.buffercache'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end
local db_list = helpers.connections.get_databases(helpers.connections.manager, helpers.host)

local function collect_for_db(dbname)

  local agent = helpers.connections.get_agent_connection(dbname)
  local result, err = agent:query("select gatherer.snapshot_id(300), * from gatherer.pg_buffer_cache_uses()")
  if err then error(err) end

  local per_table = {}
  local per_usage = {}
  per_usage["0"], per_usage["1"], per_usage["2"] = 0, 0, 0
  per_usage["3"], per_usage["4"], per_usage["5"] = 0, 0, 0
  local per_dirty = {dirty = 0, clean = 0}

  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

      local full_table_name = jsonb.full_table_name
      local usagecount = tostring(jsonb.usagecount)
      local isdirty = jsonb.isdirty
      local buffers = jsonb.buffers

      if full_table_name and not(usagecount == nil) and not(isdirty == nil) and not(buffers == nil) then

        -- count buffers per table
        if not per_table[full_table_name] then
          per_table[full_table_name] = buffers
        else
          per_table[full_table_name] = per_table[full_table_name] + buffers
        end

        -- count buffers usagecount
        per_usage[ tostring(usagecount) ] = per_usage[ tostring(usagecount) ] + buffers

        -- count buffers dirty
        if isdirty then
          per_dirty.dirty = per_dirty.dirty + buffers
        else
          per_dirty.clean = per_dirty.clean + buffers
        end

      end
  end

  local jsonb, err = json.encode(per_table)
  if err then error(err) end
  metric_insert(plugin..".relation", row[1], nil, nil, jsonb)
  per_table = nil

  local jsonb, err = json.encode(per_usage)
  if err then error(err) end
  metric_insert(plugin..".usage", row[1], nil, nil, jsonb)

  local jsonb, err = json.encode(per_dirty)
  if err then error(err) end
  metric_insert(plugin..".dirty", row[1], nil, nil, jsonb)

end

for _, db in pairs(db_list) do
  print("enable ", plugin, "for database: ", db)
end

local function collect()
  for _, db in pairs(db_list) do collect_for_db(db) end
end

-- run collect
helpers.runner.run_every(collect, 300)
