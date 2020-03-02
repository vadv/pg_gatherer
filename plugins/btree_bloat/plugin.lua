local plugin_name   = 'pg.btree_bloat'
local every         = 60

local sql_btree_bloat = read_file_in_plugin_dir("btree_bloat.sql")

local function collect()
  local result = target:query(sql_btree_bloat, 60)
  for _, row in pairs(result.rows) do
    local jsonb, err = json.decode(row[2])
    if err then error(err) end
    local id     = jsonb.id

    local jsonb, err     = json.encode(jsonb)
    if err then error(err) end
    storage_insert_metric({ plugin = plugin_name, snapshot = row[1], json = jsonb })
  end
end

run_every(collect, every)
