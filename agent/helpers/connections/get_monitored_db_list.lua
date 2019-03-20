local stmt = nil
local function build_stmt(manager)
  if stmt then return stmt end
  local stmt, err = manager:stmt('select unnest(databases) from manager.host where host = $1')
  if err then error(err) end
  return stmt
end

local function get_monitored_db_list(manager, host)
  stmt = build_stmt(manager)
  local result, err = stmt:query(host)
  if err then error(err) end
  local db = {}
  for k, db in pairs(result.rows) do
    table.insert(db, v)
  end
  return db
end

return get_monitored_db_list
