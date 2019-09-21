-- this file loaded on first start of plugin

filepath = require("filepath")
time = require("time")
inspect = require("inspect")
json = require("json")
ioutil = require("ioutil")

-- current directory (root)
root = filepath.dir(debug.getinfo(1).source)

-- return true if database hosted on rds
function is_rds(conn)
  conn = conn or agent
  return not(not(
          pcall(function()
              target:query("show rds.extensions")
          end)
  ))
end

-- return postgresql version
function get_pg_server_version(conn)
  conn = conn or agent
  if pg_server_version then return pg_server_version end
  local version = target:query("show server_version")
  pg_server_version = tonumber(version.rows[1][1])
  return pg_server_version
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
