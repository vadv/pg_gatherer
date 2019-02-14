local filepath = require("filepath")
local inspect = require("inspect")
local db = require("db")
local time = require("time")

local current_dir = filepath.dir(debug.getinfo(1).source)

-- load config
local get_config = dofile(filepath.join(current_dir, "helpers", "get_config.lua"))
local config = get_config( filepath.join(current_dir, "config.yaml") )

-- make postgres connections
local agent, err = db.open("postgres", config.connections.agent)
if err then error(err) end
local manager, err = db.open("postgres", config.connections.manager)
if err then error(err) end

-- get host
local get_host = dofile(filepath.join(current_dir, "helpers", "get_host.lua"))
host = get_host(config.token, manager)

-- insert_metric
insert_metric = dofile(filepath.join(current_dir, "helpers", "insert_metric.lua"))

-- is_rds
local is_rds_func = dofile(filepath.join(current_dir, "helpers", "is_rds.lua"))
is_rds = is_rds_func(agent)

-- linux_helpers
linux_helpers = dofile(filepath.join(current_dir, "helpers", "linux.lua"))

-- counter_speed
counter_speed = dofile(filepath.join(current_dir, "helpers", "counter_speed.lua"))

-- load plugin files
local plugins, plugins_exec_times = {}, {}
for _, filename in pairs( filepath.glob( filepath.join(current_dir, "plugins", "*.lua") ) ) do
  local plugin_name = filepath.basename(filename)
  plugins[plugin_name] = dofile(filename)
end

-- start supervisor
while true do

  local now = time.unix()
  for name, f in pairs(plugins) do
    local _, err = agent:exec("SET statement_timeout TO 1000;")
    if err then print("set execution timeout:", err) end
    plugins_exec_times[name] = time.unix()
    local ok, err = pcall(f, agent, manager)
    if not ok then print("plugin ", name, " error: ", err) end
    plugins_exec_times[name] = time.unix() - plugins_exec_times[name]
  end

  -- sleep
  local sleep_time = 5 - (time.unix() - now)
  if sleep_time > 0 then
    time.sleep(sleep_time)
    print("[INFO] tick.")
  else
    print("[ERROR] execution time too big: ", inspect(plugins_exec_times))
    time.sleep(1)
  end

end
