local function get_host(token, manager)
    local result, err = manager:query(string.format("select agent.get_host('%s')", token))
    if err then error(err) end
    if (result.rows[1] == nil) or (result.rows[1][1] == nil) or (result.rows[1][1] == nil) then
      error("host for current token not found")
    end
    return result.rows[1][1]
end

return get_host
