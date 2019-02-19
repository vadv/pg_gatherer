local filepath = require("filepath")
local time = require("time")

local current_dir = filepath.dir(debug.getinfo(1).source)

-- init config
local helpers = dofile(filepath.join(current_dir, "helpers", "init.lua"))
helpers.config.load(filepath.join(current_dir, "config.yaml"))

local plugins = dofile(filepath.join(current_dir, "plugins", "init.lua"))

-- start supervisor
while true do
  time.sleep(5)
  for name, plugin in pairs(plugins) do
    if not plugin:is_running() then
      print("plugin", name, "error:", tostring(plugin:error()), "restart it")
      plugin:run()
    end
  end
  print("tick")
end
