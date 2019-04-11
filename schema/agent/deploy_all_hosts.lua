-- deploy functions to target database from manager instance

local db = require("db")
local filepath = require("filepath")
local ioutil = require("ioutil")
local manager_conn_str = os.getenv("MANAGER")
if not manager_conn_str then error("you must be set MANAGER env variable") end

local manager, err = db.open("postgres", manager_conn_str)
if err then error(err) end

local result, err = manager:query("select name, agent_connection, additional_agent_connections from manager.host where not maintenance")
if err then error(err) end

local current_dir = filepath.dir(debug.getinfo(1).source)

local function load_file(conn, filename)
  local data, err = ioutil.read_file(filename)
  if err then error(err) end
  local _, err = conn:exec(data)
  if err then
    print("load", filename, err)
  end
end

for _, row in pairs(result.rows) do
  local host, agent_conn, additional_conns = row[1], row[2], row[3]
  print("deploy to host:", host)
  local conn, err = db.open("postgres", agent_conn)
  if err then
    print("connect to", host, err)
  else
    load_file(conn, filepath.join(current_dir, "init.sql"))
    for _, filename in pairs( filepath.glob(filepath.join(current_dir, "plugin_*.sql")) ) do
      load_file(conn, filename)
    end
    conn:close()
  end
end
