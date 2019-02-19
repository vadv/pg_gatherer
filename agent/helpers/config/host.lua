local function host(token, manager)
  local stmt, err = manager:stmt('select agent.get_host($1::text)')
  if err then error(err) end
  local result, err = stmt:query(token)
  if err then error("exec error: "..err) end
  if (result.rows[1] == nil) or (result.rows[1][1] == nil) or (result.rows[1][1] == nil) then
    error("host for current token not found")
  end
  return result.rows[1][1]
end

return host
