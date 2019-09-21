-- this file loaded on first start of plugin

filepath = require("filepath")
time = require("time")
inspect = require("inspect")
json = require("json")
ioutil = require("ioutil")
crypto = require("crypto")
goos = require("goos")

-- current directory (root)
root = filepath.dir(debug.getinfo(1).source)

HOST_DEV_DIR = os.getenv('HOST_DEV_DIR') or '/dev'
HOST_SYS_DIR = os.getenv('HOST_SYS_DIR') or '/sys'
HOST_PROC_DIR = os.getenv('HOST_PROC_DIR') or '/proc'

-- return true if database hosted on rds
function is_rds()
  return not(not(
          pcall(function()
              agent:query("show rds.extensions")
          end)
  ))
end

-- return postgresql version
function get_pg_server_version()
  if pg_server_version then return pg_server_version end
  local version = agent:query("show server_version")
  pg_server_version = tonumber(version.rows[1][1])
  return pg_server_version
end

-- return in pg_in_recovery
function get_pg_is_in_recovery()
  local pg_is_in_recovery = agent:query("select pg_catalog.pg_is_in_recovery()")
  return pg_is_in_recovery.rows[1][1]
end

-- run function f every sec
-- this function run in plugin context, then we use cache key `last_run`
function run_every(f, every)
  while true do

    local _, updated_at = cache:get("last_run")
    updated_at = updated_at or 0

    if time.unix() >= updated_at + every then
      local start_at = time.unix()
      cache:set("last_run", 0)
      f()
      local exec_time = (time.unix() - start_at)
      if exec_time > every then
        print(debug.getinfo(2).source, "execution timeout:", exec_time)
        time.sleep(1)
      end
    else
      -- wait
      time.sleep(1)
    end

  end
end
