local db = require("db")

local connections = {
-- connection_string = ud
}

local function agent(connection_string)

  -- connection_string == nil - return main connection
  if connection_string == nil then
    -- env already set
    if os.getenv("MAIN_AGENT_CONNECTION") then
      if connections[os.getenv("MAIN_AGENT_CONNECTION")] == nil then
        -- build connection
        local conn, err = db.open("postgres", os.getenv("MAIN_AGENT_CONNECTION"), {shared=true, read_only=true})
        if err then error(err) end
        connections[os.getenv("MAIN_AGENT_CONNECTION")] = conn
        return conn
      else
        return connections[os.getenv("MAIN_AGENT_CONNECTION")]
      end
    end
    -- get agent connection
    local manager, err = db.open("postgres", os.getenv("MANAGER"), {shared=true})
    if err then error(err) end
    local stmt, err = manager:stmt("select agent.get_agent_connection($1)")
    if err then error(err) end
    local result, err = stmt:query(os.getenv("TOKEN"))
    if err then error(err) end
    if (result.rows == nil) or (result.rows[1] == nil) or (result.rows[1][1] == nil) then
      error("agent connection not found, may be invalid token")
    end
    stmt:close()
    os.setenv("MAIN_AGENT_CONNECTION", result.rows[1][1])
    local conn, err = db.open("postgres", os.getenv("MAIN_AGENT_CONNECTION"), {shared=true, read_only=true})
    if err then error(err) end
    connections[os.getenv("MAIN_AGENT_CONNECTION")] = conn
    return conn
  end

  -- already set
  if connections[connection_string] then
    return connections[connection_string]
  end

  local conn, err = db.open("postgres", connection_string, {shared=true, read_only=true})
  if err then error(err) end
  connections[connection_string] = conn
  return conn
end

return agent
