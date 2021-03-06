local sql = read_file_in_plugin_dir("wraparound.sql")
local key = "wraparound"

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not (result.rows[1] == nil) and not (result.rows[1][1] == nil) then
    local database, age = result.rows[1][1], result.rows[1][2]
    local jsonb      = {
      host           = host,
      key            = key,
      created_at     = get_last_created_at(host, key, unix_ts),
      custom_details = { database=database, age=age }
    }
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage:insert_metric({ host = host, plugin = plugin_name, json = jsonb })
  end
end

return check
