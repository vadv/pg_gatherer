local sql = read_file_in_plugin_dir("uptime.sql")

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not (result.rows[1] == nil) and not (result.rows[1][1] == nil) then
    local uptime = result.rows[1][1]
    print("uptime: ", host, uptime)
    if uptime < 60 then
      local jsonb      = {
        host           = host,
        key            = 'checkpointer.uptime',
        custom_details = { uptime = uptime }
      }
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      storage:insert_metric({ host = host, plugin = 'pg.alerts', json = jsonb })
    end
  end
end

return check
