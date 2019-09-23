local plugin_name     = 'pg.healthcheck'
local every           = 60

local sql_healthcheck = read_file_in_plugin_dir("healthcheck.sql")

local function collect()
  local result = target:query(sql_healthcheck, every)
  storage_insert_metric({ plugin = plugin_name, snapshot = result.rows[1][1], int = result.rows[1][1] })
end

run_every(collect, every)
