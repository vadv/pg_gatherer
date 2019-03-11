local time = require("time")

local helpers = dofile(os.getenv("CONFIG_INIT"))
local manager = helpers.connections.manager
local function get_hosts()
  return helpers.query.get_hosts(helpers.connections.manager)
end

if not(os.getenv("TELEGRAM_ENABLED") == "true") then
  while true do
    -- disable telegram
    time.sleep(60)
  end
end

local stmt, err = manager:stmt("select key, info from manager.alert where host = $1")
if err then error(err) end

function collect()
  for _, host in pairs(get_hosts()) do
   --
  end
end

helpers.runner.run_every(collect, 5)
