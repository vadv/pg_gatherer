local plugin         = 'pg.block'
local every          = 5

local current_dir    = filepath.join(root, "block")
local sql_block, err = ioutil.read_file(filepath.join(current_dir, "block.sql"))
if err then error(err) end

local function collect()
  local result = connection:query(sql_block, every)
  for _, row in pairs(result.rows) do
    manager:send_metric({ plugin = plugin, snapshot = row[1], json = row[2] })
  end
end

run_every(collect, every)
