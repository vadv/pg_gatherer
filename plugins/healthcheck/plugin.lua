local plugin               = 'pg.healthcheck'
local every                = 10

local current_dir          = filepath.join(root, "healthcheck")
local sql_healthcheck, err = ioutil.read_file(filepath.join(current_dir, "healthcheck.sql"))
if err then error(err) end

local function collect()
  local result = connection:query(sql_healthcheck, every)
  manager:send_metric({ plugin = plugin, snapshot = result.rows[1][1], int = result.rows[1][1] })
end

run_every(collect, every)
