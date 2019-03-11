local filepath = require("filepath")
local plugin = require("plugin")

local current_dir = filepath.dir(debug.getinfo(1).source)
local plugins = {}

local helpers = dofile(os.getenv("CONFIG_INIT"))

if helpers.is_rds then
  print("detected rds instance, linux metrics are disabled")
else
  -- load linux
  for _, filename in pairs( filepath.glob( filepath.join(current_dir, "linux", "*.lua") ) ) do
    print("load linux plugin", filename)
    plugins[filename] = plugin.do_file(filename)
  end
end

-- load pg
for _, filename in pairs( filepath.glob( filepath.join(current_dir, "pg", "*.lua") ) ) do
  print("load pg plugin", filename)
  plugins[filename] = plugin.do_file(filename)
end

-- start it
for _, p in pairs( plugins ) do
  p:run()
end

return plugins
