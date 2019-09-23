local sql = read_file_in_plugin_dir("long_running_transactions.sql")

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not (result.rows[1] == nil) and not (result.rows[1][1] == nil) then
    local info, err = json.decode(result.rows[1][1])
    if err then error(err) end
    local jsonb      = {
      host           = host,
      key            = 'long_running_transactions',
      custom_details = info,
    }
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage:insert_metric({ host = host, plugin = 'pg.alerts', json = jsonb })
  end
end

return check
