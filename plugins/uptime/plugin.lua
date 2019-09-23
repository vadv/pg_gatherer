local plugin_name             = 'pg.uptime'
local every                   = 300

local sql_uptime              = read_file_in_plugin_dir("uptime.sql")
local sql_checkpointer_uptime = read_file_in_plugin_dir("checkpointer_uptime_10.sql")

local function collect_9()
  local result = target:query(sql_uptime)
  for _, row in pairs(result.rows) do
    storage_insert_metric({ plugin = plugin_name, int = row[1] })
  end
end

local function collect_10()
  local result = target:query(sql_uptime)
  for _, row in pairs(result.rows) do
    storage_insert_metric({ plugin = plugin_name, int = row[1] })
  end
  local result = target:query(sql_checkpointer_uptime)
  for _, row in pairs(result.rows) do
    storage_insert_metric({ plugin = plugin_name .. ".checkpointer", int = row[1] })
  end
end

local collect = collect_9
if get_pg_server_version() >= 10 then collect = collect_10 end
run_every(collect, every)
