local json = require('json')
local time = require('time')
local plugin = 'pg.user_tables'

local helpers = dofile(os.getenv("CONFIG_INIT"))

local agent = helpers.connections.agent
local function metric_insert(key, snapshot, value_bigint, value_double, value_jsonb)
  helpers.metric.insert(helpers.host, key, snapshot, value_bigint, value_double, value_jsonb, helpers.connections.manager)
end

local function collect()

  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_user_tables()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local table_name = jsonb.full_table_name
    jsonb.vacuum_count = helpers.metric.speed(table_name..".vacuum_count", jsonb.vacuum_count)
    jsonb.autovacuum_count = helpers.metric.diff(table_name..".autovacuum_count", jsonb.autovacuum_count)
    jsonb.analyze_count = helpers.metric.diff(table_name..".analyze_count", jsonb.analyze_count)
    jsonb.autoanalyze_count = helpers.metric.diff(table_name..".autoanalyze_count", jsonb.autoanalyze_count)
    jsonb.seq_scan = helpers.metric.speed(table_name..".seq_scan", jsonb.seq_scan)
    jsonb.seq_tup_read = helpers.metric.speed(table_name..".seq_tup_read", jsonb.seq_tup_read)
    jsonb.idx_scan = helpers.metric.speed(table_name..".idx_scan", jsonb.idx_scan)
    jsonb.idx_tup_fetch = helpers.metric.speed(table_name..".idx_tup_fetch", jsonb.idx_tup_fetch)
    jsonb.n_tup_ins = helpers.metric.speed(table_name..".n_tup_ins", jsonb.n_tup_ins)
    jsonb.n_tup_upd = helpers.metric.speed(table_name..".n_tup_upd", jsonb.n_tup_upd)
    jsonb.n_tup_del = helpers.metric.speed(table_name..".n_tup_del", jsonb.n_tup_del)
    jsonb.n_tup_hot_upd = helpers.metric.speed(table_name..".n_tup_hot_upd", jsonb.n_tup_hot_upd)
    jsonb.n_live_tup = jsonb.n_live_tup or 0
    jsonb.n_dead_tup = jsonb.n_dead_tup or 0
    jsonb.n_mod_since_analyze = helpers.metric.speed(table_name..".n_mod_since_analyze", jsonb.n_mod_since_analyze)

    if jsonb.vacuum_count and jsonb.autovacuum_count and jsonb.analyze_count and
        jsonb.autoanalyze_count and jsonb.seq_scan and jsonb.seq_tup_read and jsonb.idx_scan and
        jsonb.idx_tup_fetch and jsonb.idx_tup_fetch and jsonb.n_tup_ins and jsonb.n_tup_upd and
        jsonb.n_tup_del and jsonb.n_tup_hot_upd then
       if jsonb.vacuum_count + jsonb.autovacuum_count + jsonb.analyze_count +
        jsonb.autoanalyze_count + jsonb.seq_scan + jsonb.seq_tup_read + jsonb.idx_scan +
        jsonb.idx_tup_fetch + jsonb.idx_tup_fetch + jsonb.n_tup_ins + jsonb.n_tup_upd +
        jsonb.n_tup_del + jsonb.n_tup_hot_upd > 0 then
          local jsonb, err = json.encode(jsonb)
          if err then error(err) end
          metric_insert(plugin, row[1], nil, nil, jsonb)
       end
    end
  end

  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_statio_user_tables()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local table_name = jsonb.full_table_name
    jsonb.heap_blks_read = helpers.metric.speed(table_name..".heap_blks_read", jsonb.heap_blks_read)
    jsonb.heap_blks_hit = helpers.metric.speed(table_name..".heap_blks_hit", jsonb.heap_blks_hit)
    jsonb.idx_blks_read = helpers.metric.speed(table_name..".idx_blks_read", jsonb.idx_blks_read)
    jsonb.idx_blks_hit = helpers.metric.speed(table_name..".idx_blks_hit", jsonb.idx_blks_hit)
    jsonb.toast_blks_read = helpers.metric.speed(table_name..".toast_blks_read", jsonb.toast_blks_read)
    jsonb.toast_blks_hit = helpers.metric.speed(table_name..".toast_blks_hit", jsonb.toast_blks_hit)
    jsonb.tidx_blks_read = helpers.metric.speed(table_name..".tidx_blks_read", jsonb.tidx_blks_read)
    jsonb.tidx_blks_hit = helpers.metric.speed(table_name..".tidx_blks_hit", jsonb.tidx_blks_hit)

    if jsonb.heap_blks_read and jsonb.heap_blks_hit and jsonb.idx_blks_read and jsonb.idx_blks_hit and
        jsonb.toast_blks_read and jsonb.toast_blks_hit and jsonb.tidx_blks_read and jsonb.tidx_blks_hit then
       if jsonb.heap_blks_read + jsonb.heap_blks_hit + jsonb.idx_blks_read + jsonb.idx_blks_hit +
        jsonb.toast_blks_read + jsonb.toast_blks_hit + jsonb.tidx_blks_read + jsonb.tidx_blks_hit > 0 then
          local jsonb, err = json.encode(jsonb)
          if err then error(err) end
          metric_insert(plugin..".io", row[1], nil, nil, jsonb)
       end
    end
  end

end

-- run collect
helpers.runner.run_every(collect, 60)
