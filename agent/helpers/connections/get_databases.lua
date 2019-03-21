local stmt = nil
local function build_stmt(manager)
  if stmt then return stmt end
  local stmt, err = manager:stmt('select * from agent.get_databases($1)')
  if err then error(err) end
  return stmt
end

local function get_databases(manager, host)
  stmt = build_stmt(manager)
  local result, err = stmt:query(host)
  if err then error(err) end
  local db = {}
  for k, v in pairs(result.rows) do
    table.insert(db, v[1])
  end
  return db
end

return get_databases
