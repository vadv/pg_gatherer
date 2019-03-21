local json = require('json')
local time = require('time')
local plugin = 'pg.user_tables'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end
local db_list = helpers.connections.get_databases(helpers.connections.manager, helpers.host)

local function collect_for_db(dbname)

  local agent = helpers.connections.get_agent_connection(dbname)
  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_user_tables()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
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
        local jsonb, err = json.encode(jsonb)
        if err then error(err) end
        metric_insert(plugin, row[1], nil, nil, jsonb)
    end
  end

  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_statio_user_tables()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
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
        local jsonb, err = json.encode(jsonb)
        if err then error(err) end
        metric_insert(plugin..".io", row[1], nil, nil, jsonb)
    end
  end

end

for _, db in pairs(db_list) do
  print("enable ", plugin, "for database: ", db)
end

local function collect()
  for _, db in pairs(db_list) do collect_for_db(db) end
end

-- run collect
helpers.runner.run_every(collect, 60)
