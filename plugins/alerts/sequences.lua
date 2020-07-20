local sql = read_file_in_plugin_dir("sequences.sql")
local key = "sequences"

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not(result.rows[1] == nil) and not(result.rows[1][1] == nil) then
    local sequence_name, remaining_capacity = result.rows[1][1], result.rows[1][2]
    local jsonb = {
      host           = host,
      key            = key,
      created_at     = get_last_created_at(host, key, unix_ts),
      custom_details ={sequence_name=sequence_name, remaining_capacity=remaining_capacity}
    }
    local jsonb, err = json.encode(jsonb)
    if err then error(err) end
    storage:insert_metric({ host = host, plugin = plugin_name, json = jsonb })
  end
end

return check
