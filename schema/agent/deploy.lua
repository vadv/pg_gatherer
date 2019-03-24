-- deploy functions to target database

local db = require("db")
local filepath = require("filepath")
local ioutil = require("ioutil")

local conn_string = os.getenv("AGENT_PRIV")
if not conn_string then error("you must be set AGENT_DEPLOY_CONNECTION env variable") end

local conn, err = db.open("postgres", conn_string)
if err then error(err) end

local current_dir = filepath.dir(debug.getinfo(1).source)

local function load_file(filename)
  local data, err = ioutil.read_file(filename)
  if err then error(err) end
  local _, err = conn:exec(data)
  if err then error(err) end
end

-- init
load_file( filepath.join(current_dir, "init.sql") )

-- plugins
for _, filename in pairs( filepath.glob(filepath.join(current_dir, "plugin_*.sql")) ) do
  print("load", filename)
  load_file(filename)
end
