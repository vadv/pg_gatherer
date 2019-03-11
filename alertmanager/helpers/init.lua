local filepath  = require('filepath')

local current_dir = filepath.dir(debug.getinfo(1).source)

local helpers = {}

-- config
helpers.config = {}
helpers.config.load = dofile(filepath.join(current_dir, "config", "load.lua"))

-- runner
helpers.runner = {}
helpers.runner.run_every = dofile(filepath.join(current_dir, "runner", "run_every.lua"))

if os.getenv("CONFIG_INITILIZED") == "TRUE" then
  helpers.connections = {}
  helpers.connections.manager = dofile(filepath.join(current_dir, "connections", "manager.lua"))
  helpers.query = {}
  helpers.query.get_hosts = dofile(filepath.join(current_dir, "query", "get_hosts.lua"))
  helpers.query.create_alert = dofile(filepath.join(current_dir, "query", "create_alert.lua"))
  helpers.query.resolve_alert = dofile(filepath.join(current_dir, "query", "resolve_alert.lua"))
end

return helpers
