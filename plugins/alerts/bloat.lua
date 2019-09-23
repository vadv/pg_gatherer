local sql = read_file_in_plugin_dir("bloat.sql")

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not(result.rows[1] == nil) and not(result.rows[1][1] == nil) then
    local table_name, bloat = result.rows[1][1], result.rows[1][2]
    local jsonb = {
      host = host,
      key = 'bloat',
      custom_details={table_name=table_name, bloat=bloat}
    }
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage:insert_metric({host=host, plugin='pg.alerts', json=jsonb})
  end
end

return check
