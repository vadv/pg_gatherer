local plugin_name   = 'pg.sequences'
local every         = 60
local sql_sequences = read_file_in_plugin_dir("sequences.sql")

local function collect_for_db(conn)
  local result = conn:query(sql_sequences, every)
  for _, row in pairs(result.rows) do
    storage_insert_metric({ plugin = plugin_name, snapshot = row[1], json = row[2] })
  end
end

local function collect()
  for _, conn in pairs(target:available_connections()) do
    collect_for_db(conn)
  end
end

run_every(collect, every)
