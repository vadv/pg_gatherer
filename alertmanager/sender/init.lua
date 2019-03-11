local filepath = require("filepath")
local plugin = require("plugin")

local current_file = debug.getinfo(1).source
local current_dir = filepath.dir(current_file)
local senders = {}

local helpers = dofile(os.getenv("CONFIG_INIT"))

-- load pg
for _, filename in pairs( filepath.glob( filepath.join(current_dir, "*.lua") ) ) do
  if not(filename == current_file) then
    print("load sender", filename)
    senders[filename] = plugin.do_file(filename)
  end
end

-- start it
for _, p in pairs( senders ) do
  p:run()
end

return senders
