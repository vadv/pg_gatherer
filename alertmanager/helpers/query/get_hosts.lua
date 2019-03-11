local function get_hosts(manager)
  local hosts = {}
  local result, err = manager:query('select host from manager.host where not maintenance')
  if err then error(err) end
  for _, row in pairs(result.rows) do
    table.insert(hosts, row[1])
  end
end

return get_hosts
