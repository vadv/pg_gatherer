local plugin          = 'pg.user_tables'
local every           = 60

local current_dir     = filepath.join(root, "user_tables")
local sql_user_tables, err = ioutil.read_file(filepath.join(current_dir, "user_tables.sql"))
if err then error(err) end

local sql_user_tables_io, err = ioutil.read_file(filepath.join(current_dir, "user_tables_io.sql"))
if err then error(err) end

local snapshot = nil
local user_tables_stat_data, user_tables_io_data = {}, {}

local function collect_for_db()
  local result = agent:query(sql_user_tables, every)
  for _, row in pairs(result.rows) do
    if not snapshot then snapshot = row[1] end
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local table_name = jsonb.full_table_name
    jsonb.vacuum_count = cache:diff_and_set(table_name..".vacuum_count", jsonb.vacuum_count or 0)
    jsonb.autovacuum_count = cache:diff_and_set(table_name..".autovacuum_count", jsonb.autovacuum_count or 0)
    jsonb.analyze_count = cache:diff_and_set(table_name..".analyze_count", jsonb.analyze_count or 0)
    jsonb.autoanalyze_count = cache:diff_and_set(table_name..".autoanalyze_count", jsonb.autoanalyze_count or 0)
    jsonb.seq_scan = cache:diff_and_set(table_name..".seq_scan", jsonb.seq_scan or 0)
    jsonb.seq_tup_read = cache:diff_and_set(table_name..".seq_tup_read", jsonb.seq_tup_read or 0)
    jsonb.idx_scan = cache:diff_and_set(table_name..".idx_scan", jsonb.idx_scan or 0)
    jsonb.idx_tup_fetch = cache:diff_and_set(table_name..".idx_tup_fetch", jsonb.idx_tup_fetch or 0)
    jsonb.n_tup_ins = cache:diff_and_set(table_name..".n_tup_ins", jsonb.n_tup_ins or 0)
    jsonb.n_tup_upd = cache:diff_and_set(table_name..".n_tup_upd", jsonb.n_tup_upd or 0)
    jsonb.n_tup_del = cache:diff_and_set(table_name..".n_tup_del", jsonb.n_tup_del or 0)
    jsonb.n_tup_hot_upd = cache:diff_and_set(table_name..".n_tup_hot_upd", jsonb.n_tup_hot_upd or 0)
    jsonb.n_live_tup = jsonb.n_live_tup or 0
    jsonb.n_dead_tup = jsonb.n_dead_tup or 0
    jsonb.n_mod_since_analyze = cache:diff_and_set(table_name..".n_mod_since_analyze", jsonb.n_mod_since_analyze or 0)
    jsonb.relpages = jsonb.relpages or 0

    if jsonb.vacuum_count or jsonb.autovacuum_count or jsonb.analyze_count or
        jsonb.autoanalyze_count or jsonb.seq_scan or jsonb.seq_tup_read or jsonb.idx_scan or
        jsonb.idx_tup_fetch or jsonb.idx_tup_fetch or jsonb.n_tup_ins or jsonb.n_tup_upd or
        jsonb.n_tup_del or jsonb.n_tup_hot_upd then
        table.insert(user_tables_stat_data, jsonb)
    end
  end

  snapshot = nil

  local result = agent:query(sql_user_tables_io, every)
  for _, row in pairs(result.rows) do
    if not snapshot then snapshot = row[1] end
    local jsonb, err = json.decode(row[2])
    if err then error(err) end

    local table_name = jsonb.full_table_name
    jsonb.heap_blks_read = cache:diff_and_set(table_name..".heap_blks_read", jsonb.heap_blks_read or 0)
    jsonb.heap_blks_hit = cache:diff_and_set(table_name..".heap_blks_hit", jsonb.heap_blks_hit or 0)
    jsonb.idx_blks_read = cache:diff_and_set(table_name..".idx_blks_read", jsonb.idx_blks_read or 0)
    jsonb.idx_blks_hit = cache:diff_and_set(table_name..".idx_blks_hit", jsonb.idx_blks_hit or 0)
    jsonb.toast_blks_read = cache:diff_and_set(table_name..".toast_blks_read", jsonb.toast_blks_read or 0)
    jsonb.toast_blks_hit = cache:diff_and_set(table_name..".toast_blks_hit", jsonb.toast_blks_hit or 0)
    jsonb.tidx_blks_read = cache:diff_and_set(table_name..".tidx_blks_read", jsonb.tidx_blks_read or 0)
    jsonb.tidx_blks_hit = cache:diff_and_set(table_name..".tidx_blks_hit", jsonb.tidx_blks_hit or 0)

    if jsonb.heap_blks_read or jsonb.heap_blks_hit or jsonb.idx_blks_read or jsonb.idx_blks_hit or
        jsonb.toast_blks_read or jsonb.toast_blks_hit or jsonb.tidx_blks_read or jsonb.tidx_blks_hit then
        table.insert(user_tables_io_data, jsonb)
    end
  end

end

local function collect()
  snapshot, user_tables_stat_data, user_tables_io_data = nil, {}, {}
  for _, conn in pairs(agent:available_connections()) do
    collect_for_db(conn)
  end
  local jsonb, err = json.encode(user_tables_stat_data)
  if err then error(err) end
  manager:insert_metric({plugin=plugin, snapshot=snapshot, json=jsonb})

  local jsonb, err = json.encode(user_tables_io_data)
  if err then error(err) end
  manager:insert_metric({plugin=plugin..".io", snapshot=snapshot, json=jsonb})
end

run_every(collect, every)
