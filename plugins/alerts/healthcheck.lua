local sql = read_file_in_plugin_dir("healthcheck.sql")
local key = "healthcheck"

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if (result.rows[1] == nil) or (result.rows[1][1] == nil) or
      math.abs(result.rows[1][2] - result.rows[1][1]) > 5 * 60 then
    local jsonb      = {
      host       = host,
      key        = key,
      created_at = get_last_created_at(host, key, unix_ts)
    }
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage:insert_metric({ host = host, plugin = plugin_name, json = jsonb })
  end
end

return check
