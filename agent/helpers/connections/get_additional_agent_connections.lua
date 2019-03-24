local db = require("db")

local additional_agent_connections = nil

local function get_additional_agent_connections()

  -- return from cache
  if additional_agent_connections then
    return additional_agent_connections
  end

  -- execute query
  local manager, err = db.open("postgres", os.getenv("MANAGER"), {shared=true})
  if err then error(err) end
  local stmt, err = manager:stmt("select agent.get_additional_agent_connections($1)")
  if err then error(err) end
  local result, err = stmt:query(os.getenv("TOKEN"))
  if err then error(err) end
  stmt:close()

  -- parse query
  local dbs = {}
  for _, row in pairs( result.rows ) do
    table.insert(dbs, row[1])
  end

  -- save and return
  additional_agent_connections = dbs
  return dbs
end

return get_additional_agent_connections
