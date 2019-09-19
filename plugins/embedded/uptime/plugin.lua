local plugin          = 'pg.uptime'
local every           = 300

local current_dir     = filepath.join(root, "embedded", "uptime")
local sql_uptime, err = ioutil.read_file(filepath.join(current_dir, "uptime.sql"))
if err then error(err) end
local sql_checkpointer_uptime, err = ioutil.read_file(filepath.join(current_dir, "checkpointer_uptime_10.sql"))
if err then error(err) end

local function collect_9()
  local result = connection:query(sql_uptime)
  for _, row in pairs(result.rows) do
    manager:send_metric({ plugin = plugin, int = row[1] })
  end
end

local function collect_10()
  local result = connection:query(sql_uptime)
  for _, row in pairs(result.rows) do
    manager:send_metric({ plugin = plugin, int = row[1] })
  end
  local result = connection:query(sql_checkpointer_uptime)
  for _, row in pairs(result.rows) do
    manager:send_metric({ plugin = plugin .. ".checkpointer", int = row[1] })
  end
end

local collect = collect_9
if get_pg_server_version() >= 10 then collect = collect_10 end
run_every(collect, every)