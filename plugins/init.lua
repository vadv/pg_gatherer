-- this file loaded on first start of plugin

filepath   = require("filepath")
time       = require("time")
inspect    = require("inspect")
json       = require("json")
ioutil     = require("ioutil")
crypto     = require("crypto")
goos       = require("goos")
log        = require("log")
humanize   = require("humanize")
strings    = require("strings")

plugin_log = log.new()
plugin_log:set_flags({ date = true, time = true })

-- current directory (root)
root          = filepath.dir(debug.getinfo(1).source)

HOST_DEV_DIR  = os.getenv('HOST_DEV_DIR') or '/dev'
HOST_SYS_DIR  = os.getenv('HOST_SYS_DIR') or '/sys'
HOST_PROC_DIR = os.getenv('HOST_PROC_DIR') or '/proc'

-- read file in plugin dir
function read_file_in_plugin_dir(filename)
  local data, err = ioutil.read_file(filepath.join(plugin:dir(), filename))
  if err then error(err) end
  return data
end

-- return true if database hosted on rds
function is_rds()
  return not (not (
      pcall(function()
        target:query("show rds.extensions")
      end)
  ))
end

-- return unix ts from connection
function get_unix_ts(conn)
  conn = conn or target
  return conn:query("select extract(epoch from now())::int").rows[1][1]
end

-- insert metric with plugin:host()
function storage_insert_metric(metric)
  if not (metric.host) then metric.host = plugin:host() end
  if (metric.int == nil) and (metric.float == nil) and not (metric.json == nil) then
    local jsonb, err = json.decode(metric.json)
    if err then error(err) end
    if next(jsonb) == nil then
      plugin_log:printf("[ERROR] plugin '%s' on host '%s': empty metric\n", plugin:name(), plugin:host())
      return
    end
  end
  storage:insert_metric(metric)
end

-- return postgresql version
function get_pg_server_version()
  if pg_server_version then return pg_server_version end
  local version     = target:query("show server_version")
  pg_server_version = tonumber(version.rows[1][1])
  return pg_server_version
end

-- return in pg_in_recovery
function get_pg_is_in_recovery()
  local pg_is_in_recovery = target:query("select pg_catalog.pg_is_in_recovery()")
  return pg_is_in_recovery.rows[1][1]
end

-- return true if extension installed
function extension_present(conn, extname)
  local extension = conn:query("select count(extname) from pg_catalog.pg_extension where extname = $1", extname)
  return (extension.rows[1][1] == 1)
end

-- run function f every sec
-- this function run in plugin context, then we use cache key `last_run`
function run_every(f, every)
  while true do
    local last_run_at = cache:get("last_run") or 0
    if time.unix() >= last_run_at + every then
      local start_at = time.unix()
      cache:set("last_run", start_at)
      f()
      local exec_time = (time.unix() - start_at)
      if exec_time > every then
        plugin_log:printf("[ERROR] plugin '%s' on host '%s' execution timeout: %.2f s\n", plugin:name(), plugin:host(), exec_time)
        time.sleep(1)
      else
        plugin_log:printf("[INFO] plugin '%s' on host '%s' execution time: %.2f s\n", plugin:name(), plugin:host(), exec_time)
      end
    else
      -- wait random seconds, for decrease CPU spikes
      local rand = every / 10
      time.sleep(math.random(rand))
    end
  end
end

-- wait random seconds, for decrease CPU spikes
time.sleep(math.random(5))