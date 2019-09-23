local sql = read_file_in_plugin_dir("errors.sql")

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not (result.rows[1] == nil) and not (result.rows[1][1] == nil) then
    local percentile_90_rollbacks, percentile_90_conflicts = result.rows[1][1], result.rows[1][2]
    if (percentile_90_rollbacks > 5000) or (percentile_90_conflicts > 100) then
      local jsonb      = {
        host           = host,
        key            = 'errors',
        custom_details = {
          percentile_90_rollbacks = percentile_90_rollbacks,
          percentile_90_conflicts = percentile_90_conflicts,
        }
      }
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      storage:insert_metric({ host = host, plugin = 'pg.alerts', json = jsonb })
    end
  end
end

return check
