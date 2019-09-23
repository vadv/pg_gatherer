local sql = read_file_in_plugin_dir("wraparound.sql")

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not (result.rows[1] == nil) and not (result.rows[1][1] == nil) then
    local database, age = result.rows[1][1], result.rows[1][2]
    local jsonb      = {
      host           = host,
      key            = 'wraparound',
      custom_details = { database=database, age=age }
    }
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage:insert_metric({ host = host, plugin = 'pg.alerts', json = jsonb })
  end
end

return check
