local json = require('json')
local crypto = require('crypto')
local plugin = 'pg.statements'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.agent()
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(key, snapshot, value_bigint, value_double, value_jsonb, helpers.manager)
end

local function collect()
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_statements()")
  if err then error(err) end

  local statements_data, snapshot = {}, nil
  for _, row in pairs(result.rows) do
    if not snapshot then snapshot = row[1] end
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local key = plugin..crypto.md5(tostring(jsonb.queryid)..tostring(jsonb.query)..tostring(jsonb.dbname)..tostring(jsonb.user))

    jsonb.calls = helpers.metric.diff(key..".calls", jsonb.calls)
    jsonb.rows = helpers.metric.diff(key..".rows", jsonb.rows)
    jsonb.shared_blks_hit = helpers.metric.diff(key..".shared_blks_hit", jsonb.shared_blks_hit)
    jsonb.shared_blks_read = helpers.metric.diff(key..".shared_blks_read", jsonb.shared_blks_read)
    jsonb.shared_blks_dirtied = helpers.metric.diff(key..".shared_blks_dirtied", jsonb.shared_blks_dirtied)
    jsonb.shared_blks_written = helpers.metric.diff(key..".shared_blks_written", jsonb.shared_blks_written)
    jsonb.local_blks_hit = helpers.metric.diff(key..".local_blks_hit", jsonb.local_blks_hit)
    jsonb.local_blks_read = helpers.metric.diff(key..".local_blks_read", jsonb.local_blks_read)
    jsonb.local_blks_dirtied = helpers.metric.diff(key..".local_blks_dirtied", jsonb.local_blks_dirtied)
    jsonb.local_blks_written = helpers.metric.diff(key..".local_blks_written", jsonb.local_blks_written)
    jsonb.temp_blks_read = helpers.metric.diff(key..".temp_blks_read", jsonb.temp_blks_read)
    jsonb.temp_blks_written = helpers.metric.diff(key..".temp_blks_written", jsonb.temp_blks_written)
    jsonb.total_time = helpers.metric.diff(key..".total_time", jsonb.total_time)
    jsonb.blk_read_time = helpers.metric.diff(key..".blk_read_time", jsonb.blk_read_time)
    jsonb.blk_write_time = helpers.metric.diff(key..".blk_write_time", jsonb.blk_write_time)

    if jsonb.calls and (jsonb.calls > 0) then
      table.insert(statements_data, jsonb)
    end
  end
  local jsonb, err = json.encode(statements_data)
  if err then error(err) end
  metric_insert(plugin, snapshot, nil, nil, jsonb)
end

-- run collect
helpers.runner.run_every(collect, 60)
