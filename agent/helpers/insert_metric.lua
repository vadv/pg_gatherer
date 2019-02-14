local function insert_metric(host, plugin, snapshot, value_bigint, value_double, value_jsonb, manager)
  snapshot = snapshot or 'NULL'
  value_bigint = value_bigint or 'NULL'
  value_double = value_double or 'NULL'
  if value_jsonb then
    value_jsonb = string.format(" '%s'::jsonb ", value_jsonb)
  else
    value_jsonb = 'NULL'
  end
  local query = string.format("select agent.insert_metric('%s', '%s', %s, %s, %s, %s)", host, plugin, snapshot, value_bigint, value_double, value_jsonb)
  local _, err = manager:exec(query)
  if err then error("exec query: "..query.." error: "..err) end
end

return insert_metric
