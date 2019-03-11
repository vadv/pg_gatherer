local function resolve_alert(host, key, manager)
  local stmt, err = manager:stmt('select manager.resolve_alert($1::text, $2::text)')
  if err then error(err) end
  local _, err = stmt:exec(host, key)
  if err then error("exec error: "..err) end
  local err = stmt:close()
  if err then error(err) end
end

return resolve_alert
