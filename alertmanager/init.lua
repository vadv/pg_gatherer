local filepath = require("filepath")
local time = require("time")

local current_dir = filepath.dir(debug.getinfo(1).source)

-- init config
local helpers = dofile(filepath.join(current_dir, "helpers", "init.lua"))
local config_file = os.getenv("CONFIG_FILE") or filepath.join(current_dir, "config.yaml")
helpers.config.load(config_file)

local senders = dofile(filepath.join(current_dir, "sender", "init.lua"))
local generators = dofile(filepath.join(current_dir, "generators", "init.lua"))


-- start supervisor
while true do
  time.sleep(5)

  for name, sender in pairs(senders) do
    if not sender:is_running() then
      print("sender", name, "error:", tostring(sender:error()), "restart it")
      sender:run()
    end
  end

  for name, generator in pairs(generators) do
    if not generator:is_running() then
      print("generator", name, "error:", tostring(generator:error()), "restart it")
      generator:run()
    end
  end

  print("tick")
end
