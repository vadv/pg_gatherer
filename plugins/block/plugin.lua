local plugin_name = 'pg.block'
local every       = 15

local sql_block   = read_file_in_plugin_dir("block.sql")

local function collect()
  local result = target:query(sql_block, every)
  for _, row in pairs(result.rows) do
    storage_insert_metric({ plugin = plugin_name, snapshot = row[1], json = row[2] })
  end
end

run_every(collect, every)
