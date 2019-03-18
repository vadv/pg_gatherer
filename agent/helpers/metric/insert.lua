local stmt = nil
local function build_stmt(manager)
  if stmt then return stmt end
  local stmt, err = manager:stmt('select agent.insert_metric($1::text, $2::text, $3::bigint, $4::bigint, $5::float8, $6::jsonb)')
  if err then error(err) end
  return stmt
end

local function insert(host, plugin, snapshot, value_bigint, value_double, value_jsonb, manager)
  stmt = build_stmt(manager)
  local _, err = stmt:exec(host, plugin, snapshot, value_bigint, value_double, value_jsonb)
  if err then error("exec error: "..err) end
end

return insert
