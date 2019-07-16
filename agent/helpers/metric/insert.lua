local stmt = nil
local function build_stmt(manager)
  if stmt then return stmt end
  local stmt, err = manager:stmt('select agent.insert_metric($1::text, $2::text, $3::bigint, $4::bigint, $5::float8, $6::jsonb)')
  if err then error(err) end
  return stmt
end

local function insert(plugin, snapshot, value_bigint, value_double, value_jsonb, manager)
  stmt = build_stmt(manager)
  -- fixes for glua json.encode({}) == '[]'
  if value_jsonb == '[]' then value_jsonb = nil end
  local _, err = stmt:exec(os.getenv("TOKEN"), plugin, snapshot, value_bigint, value_double, value_jsonb)
  if err then error("exec error: "..err) end
end

return insert
