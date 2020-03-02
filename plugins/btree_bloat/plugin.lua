local plugin_name   = 'pg.btree_bloat'
local every         = 60

local sql_btree_bloat = read_file_in_plugin_dir("btree_bloat.sql")

local function collect()
  local result = target:query(sql_btree_bloat, 60)
  for _, row in pairs(result.rows) do
    storage_insert_metric({ plugin = plugin_name, snapshot = row[1], json = row[2] })
  end
end

run_every(collect, every)
