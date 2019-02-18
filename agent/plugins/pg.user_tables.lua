local json = require('json')

local plugin = 'pg.user_tables'

local function main(agent, manager)

  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_stat_user_tables()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local table_name = jsonb.full_table_name
    jsonb.vacuum_count = counter_speed(table_name..".vacuum_count", jsonb.vacuum_count)
    jsonb.autovacuum_count = counter_diff(table_name..".autovacuum_count", jsonb.autovacuum_count)
    jsonb.analyze_count = counter_diff(table_name..".analyze_count", jsonb.analyze_count)
    jsonb.autoanalyze_count = counter_diff(table_name..".autoanalyze_count", jsonb.autoanalyze_count)
    jsonb.seq_scan = counter_speed(table_name..".seq_scan", jsonb.seq_scan)
    jsonb.seq_tup_read = counter_speed(table_name..".seq_tup_read", jsonb.seq_tup_read)
    jsonb.idx_scan = counter_speed(table_name..".idx_scan", jsonb.idx_scan)
    jsonb.idx_tup_fetch = counter_speed(table_name..".idx_tup_fetch", jsonb.idx_tup_fetch)
    jsonb.n_tup_ins = counter_speed(table_name..".n_tup_ins", jsonb.n_tup_ins)
    jsonb.n_tup_upd = counter_speed(table_name..".n_tup_upd", jsonb.n_tup_upd)
    jsonb.n_tup_del = counter_speed(table_name..".n_tup_del", jsonb.n_tup_del)
    jsonb.n_tup_hot_upd = counter_speed(table_name..".n_tup_hot_upd", jsonb.n_tup_hot_upd)
    jsonb.n_live_tup = jsonb.n_live_tup or 0
    jsonb.n_dead_tup = jsonb.n_dead_tup or 0
    jsonb.n_mod_since_analyze = counter_speed(table_name..".n_mod_since_analyze", jsonb.n_mod_since_analyze)

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
          insert_metric(host, plugin, row[1], nil, nil, jsonb, manager)
       end
    end
  end

  local result, err = agent:query("select gatherer.snapshot_id(), * from gatherer.pg_statio_user_tables()")
  if err then error(err) end
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local table_name = jsonb.full_table_name
    jsonb.heap_blks_read = counter_speed(table_name..".heap_blks_read", jsonb.heap_blks_read)
    jsonb.heap_blks_hit = counter_speed(table_name..".heap_blks_hit", jsonb.heap_blks_hit)
    jsonb.idx_blks_read = counter_speed(table_name..".idx_blks_read", jsonb.idx_blks_read)
    jsonb.idx_blks_hit = counter_speed(table_name..".idx_blks_hit", jsonb.idx_blks_hit)
    jsonb.toast_blks_read = counter_speed(table_name..".toast_blks_read", jsonb.toast_blks_read)
    jsonb.toast_blks_hit = counter_speed(table_name..".toast_blks_hit", jsonb.toast_blks_hit)
    jsonb.tidx_blks_read = counter_speed(table_name..".tidx_blks_read", jsonb.tidx_blks_read)
    jsonb.tidx_blks_hit = counter_speed(table_name..".tidx_blks_hit", jsonb.tidx_blks_hit)

    if jsonb.heap_blks_read and jsonb.heap_blks_hit and jsonb.idx_blks_read and jsonb.idx_blks_hit and
        jsonb.toast_blks_read and jsonb.toast_blks_hit and jsonb.tidx_blks_read and jsonb.tidx_blks_hit then
       if jsonb.heap_blks_read + jsonb.heap_blks_hit + jsonb.idx_blks_read + jsonb.idx_blks_hit +
        jsonb.toast_blks_read + jsonb.toast_blks_hit + jsonb.tidx_blks_read + jsonb.tidx_blks_hit > 0 then
          local jsonb, err = json.encode(jsonb)
          if err then error(err) end
          insert_metric(host, plugin..".io", row[1], nil, nil, jsonb, manager)
       end
    end
  end

end

return main
