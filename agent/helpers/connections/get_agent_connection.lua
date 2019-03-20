local db = require("db")
local http = require("http")

local connections = {
-- dbname = conn
}

local function build_agent_connection_string(dbname)
  local default_conn = os.getenv("CONNECTION_AGENT")
  if not dbname then return default_conn end
  local url, err = http.parse_url(default_conn)
  if err then error(err) end
  url.path = dbname
  return http.build_url(url)
end

local function get_agent_connection(dbname)

  local conn_string = build_agent_connection_string(dbname)
  if connections[dbname] then
    return connections[dbname]
  end

  local agent, err = db.open("postgres", conn_string, {shared=true})
  if err then error(err) end
  connections[dbname] = agent
  return connections[dbname]

end

return get_agent_connection
