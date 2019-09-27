local plugin_name    = 'pg.statements'
local every          = 300

local sql_statements = read_file_in_plugin_dir("statements.sql")

local function collect()
  local result                    = target:query(sql_statements, every)
  local statements_data, snapshot = {}, nil
  for _, row in pairs(result.rows) do
    if not snapshot then snapshot = row[1] end
    local jsonb, err = json.decode(row[2])
    if err then error(err) end
    local key                 = crypto.md5(tostring(jsonb.queryid) .. tostring(jsonb.query) .. tostring(jsonb.dbname) .. tostring(jsonb.user))
    jsonb.calls               = cache:diff_and_set(key .. ".calls", jsonb.calls)
    jsonb.rows                = cache:diff_and_set(key .. ".rows", jsonb.rows)
    jsonb.shared_blks_hit     = cache:diff_and_set(key .. ".shared_blks_hit", jsonb.shared_blks_hit)
    jsonb.shared_blks_read    = cache:diff_and_set(key .. ".shared_blks_read", jsonb.shared_blks_read)
    jsonb.shared_blks_dirtied = cache:diff_and_set(key .. ".shared_blks_dirtied", jsonb.shared_blks_dirtied)
    jsonb.shared_blks_written = cache:diff_and_set(key .. ".shared_blks_written", jsonb.shared_blks_written)
    jsonb.local_blks_hit      = cache:diff_and_set(key .. ".local_blks_hit", jsonb.local_blks_hit)
    jsonb.local_blks_read     = cache:diff_and_set(key .. ".local_blks_read", jsonb.local_blks_read)
    jsonb.local_blks_dirtied  = cache:diff_and_set(key .. ".local_blks_dirtied", jsonb.local_blks_dirtied)
    jsonb.local_blks_written  = cache:diff_and_set(key .. ".local_blks_written", jsonb.local_blks_written)
    jsonb.temp_blks_read      = cache:diff_and_set(key .. ".temp_blks_read", jsonb.temp_blks_read)
    jsonb.temp_blks_written   = cache:diff_and_set(key .. ".temp_blks_written", jsonb.temp_blks_written)
    jsonb.total_time          = cache:diff_and_set(key .. ".total_time", jsonb.total_time)
    jsonb.blk_read_time       = cache:diff_and_set(key .. ".blk_read_time", jsonb.blk_read_time)
    jsonb.blk_write_time      = cache:diff_and_set(key .. ".blk_write_time", jsonb.blk_write_time)
    if jsonb.calls and (jsonb.calls > 0) then
      table.insert(statements_data, jsonb)
    end
  end
  local jsonb, err = json.encode(statements_data)
  if err then error(err) end
  storage_insert_metric({ plugin = plugin_name, snapshot = snapshot, json = jsonb })
end

run_every(collect, every)
