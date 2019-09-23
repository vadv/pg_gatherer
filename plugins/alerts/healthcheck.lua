local sql = read_file_in_plugin_dir("healthcheck.sql")

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if (result.rows[1] == nil) or (result.rows[1][1] == nil) or
      math.abs(result.rows[1][2] - result.rows[1][1]) > 5 * 60 then
    local jsonb      = {
      host = host,
      key  = 'healthcheck',
    }
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage:insert_metric({ host = host, plugin = 'pg.alerts', json = jsonb })
  end
end

return check
