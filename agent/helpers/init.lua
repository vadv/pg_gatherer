local filepath  = require('filepath')

local current_dir = filepath.dir(debug.getinfo(1).source)

local helpers = {}

-- config
helpers.config = {}
helpers.config.load = dofile(filepath.join(current_dir, "config", "load.lua"))
helpers.config.host = dofile(filepath.join(current_dir, "config", "host.lua"))

-- linux
helpers.linux = {}
helpers.linux.pid_stat = dofile(filepath.join(current_dir, "linux", "pid_stat.lua"))
helpers.linux.disk_stat = dofile(filepath.join(current_dir, "linux", "disk_stat.lua"))

-- rds
helpers.rds = {}
helpers.rds.is_rds = dofile(filepath.join(current_dir, "rds", "is_rds.lua"))

-- runner
helpers.runner = {}
helpers.runner.run_every = dofile(filepath.join(current_dir, "runner", "run_every.lua"))

if os.getenv("CONFIG_INITILIZED") == "TRUE" then
  helpers.connections = {}
  helpers.connections.manager = dofile(filepath.join(current_dir, "connections", "manager.lua"))
  helpers.connections.get_agent_connection = dofile(filepath.join(current_dir, "connections", "get_agent_connection.lua"))
  helpers.is_rds = helpers.rds.is_rds( helpers.connections.get_agent_connection() )
  helpers.host = helpers.config.host( os.getenv("TOKEN"), helpers.connections.manager )
  helpers.metric = {}
  helpers.metric.speed = dofile(filepath.join(current_dir, "metric", "speed.lua"))
  helpers.metric.diff = dofile(filepath.join(current_dir, "metric", "diff.lua"))
  helpers.metric.insert = dofile(filepath.join(current_dir, "metric", "insert.lua"))
end

return helpers
