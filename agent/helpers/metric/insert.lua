local count = 0

local function insert(host, plugin, snapshot, value_bigint, value_double, value_jsonb, manager)
  local stmt, err = manager:stmt('select agent.insert_metric($1::text, $2::text, $3::bigint, $4::bigint, $5::float8, $6::jsonb)')
  if err then error(err) end
  local _, err = stmt:exec(host, plugin, snapshot, value_bigint, value_double, value_jsonb)
  if err then error("exec error: "..err) end
  -- clear plans cache
  count = count + 1
  if count % 10 == 0 then manager:exec('DISCARD PLANS') end
end

return insert
