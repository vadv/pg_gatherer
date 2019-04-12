local json = require('json')
local time = require('time')
local plugin = 'pg.user_tables'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(key, snapshot, value_bigint, value_double, value_jsonb, helpers.manager)
end

local snapshot = nil
local user_tables_stat_data, user_tables_io_data = {}, {}

local function collect_for_db(connection_string)

  local agent = helpers.agent(connection_string)
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_user_tables()")
  if err then error(err) end

  for _, row in pairs(result.rows) do
    if not snapshot then snapshot = row[1] end
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local table_name = jsonb.full_table_name
    jsonb.vacuum_count = helpers.metric.diff(table_name..".vacuum_count", jsonb.vacuum_count)
    jsonb.autovacuum_count = helpers.metric.diff(table_name..".autovacuum_count", jsonb.autovacuum_count)
    jsonb.analyze_count = helpers.metric.diff(table_name..".analyze_count", jsonb.analyze_count)
    jsonb.autoanalyze_count = helpers.metric.diff(table_name..".autoanalyze_count", jsonb.autoanalyze_count)
    jsonb.seq_scan = helpers.metric.diff(table_name..".seq_scan", jsonb.seq_scan)
    jsonb.seq_tup_read = helpers.metric.diff(table_name..".seq_tup_read", jsonb.seq_tup_read)
    jsonb.idx_scan = helpers.metric.diff(table_name..".idx_scan", jsonb.idx_scan)
    jsonb.idx_tup_fetch = helpers.metric.diff(table_name..".idx_tup_fetch", jsonb.idx_tup_fetch)
    jsonb.n_tup_ins = helpers.metric.diff(table_name..".n_tup_ins", jsonb.n_tup_ins)
    jsonb.n_tup_upd = helpers.metric.diff(table_name..".n_tup_upd", jsonb.n_tup_upd)
    jsonb.n_tup_del = helpers.metric.diff(table_name..".n_tup_del", jsonb.n_tup_del)
    jsonb.n_tup_hot_upd = helpers.metric.diff(table_name..".n_tup_hot_upd", jsonb.n_tup_hot_upd)
    jsonb.n_live_tup = jsonb.n_live_tup or 0
    jsonb.n_dead_tup = jsonb.n_dead_tup or 0
    jsonb.n_mod_since_analyze = helpers.metric.diff(table_name..".n_mod_since_analyze", jsonb.n_mod_since_analyze)
    jsonb.relpages = jsonb.relpages or 0

    if jsonb.vacuum_count or jsonb.autovacuum_count or jsonb.analyze_count or
        jsonb.autoanalyze_count or jsonb.seq_scan or jsonb.seq_tup_read or jsonb.idx_scan or
        jsonb.idx_tup_fetch or jsonb.idx_tup_fetch or jsonb.n_tup_ins or jsonb.n_tup_upd or
        jsonb.n_tup_del or jsonb.n_tup_hot_upd then
        table.insert(user_tables_stat_data, jsonb)
    end
  end
  snapshot = nil

  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_statio_user_tables()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    if not snapshot then snapshot = row[1] end
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local table_name = jsonb.full_table_name
    jsonb.heap_blks_read = helpers.metric.diff(table_name..".heap_blks_read", jsonb.heap_blks_read)
    jsonb.heap_blks_hit = helpers.metric.diff(table_name..".heap_blks_hit", jsonb.heap_blks_hit)
    jsonb.idx_blks_read = helpers.metric.diff(table_name..".idx_blks_read", jsonb.idx_blks_read)
    jsonb.idx_blks_hit = helpers.metric.diff(table_name..".idx_blks_hit", jsonb.idx_blks_hit)
    jsonb.toast_blks_read = helpers.metric.diff(table_name..".toast_blks_read", jsonb.toast_blks_read)
    jsonb.toast_blks_hit = helpers.metric.diff(table_name..".toast_blks_hit", jsonb.toast_blks_hit)
    jsonb.tidx_blks_read = helpers.metric.diff(table_name..".tidx_blks_read", jsonb.tidx_blks_read)
    jsonb.tidx_blks_hit = helpers.metric.diff(table_name..".tidx_blks_hit", jsonb.tidx_blks_hit)

    if jsonb.heap_blks_read or jsonb.heap_blks_hit or jsonb.idx_blks_read or jsonb.idx_blks_hit or
        jsonb.toast_blks_read or jsonb.toast_blks_hit or jsonb.tidx_blks_read or jsonb.tidx_blks_hit then
        table.insert(user_tables_io_data, jsonb)
    end
  end

end

local function collect()

  snapshot, user_tables_stat_data, user_tables_io_data = nil, {}, {}

  collect_for_db()
  for _, str in pairs(helpers.get_additional_agent_connections()) do
    collect_for_db(str)
  end

  local jsonb, err = json.encode(user_tables_stat_data)
  if err then error(err) end
  metric_insert(plugin, snapshot, nil, nil, jsonb)

  local jsonb, err = json.encode(user_tables_io_data)
  if err then error(err) end
  metric_insert(plugin..".io", snapshot, nil, nil, jsonb)

end

-- run collect
helpers.runner.run_every(collect, 60)
