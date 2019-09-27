local sql = read_file_in_plugin_dir("uptime.sql")
local key = "checkpointer.uptime"

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not (result.rows[1] == nil) and not (result.rows[1][1] == nil) then
    local uptime = result.rows[1][1]
    if uptime < 300 then
      local jsonb      = {
        host           = host,
        key            = key,
        created_at     = get_last_created_at(host, key, unix_ts),
        custom_details = { uptime = uptime }
      }
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      storage:insert_metric({ host = host, plugin = plugin_name, json = jsonb })
    end
  end
end

return check
