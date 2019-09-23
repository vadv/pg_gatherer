local sql = read_file_in_plugin_dir("replication_slots.sql")
local key = "replication_slots"

local function check(host, unix_ts)
  local result = storage:query(sql, host, unix_ts)
  if not (result.rows[1] == nil) and not (result.rows[1][1] == nil) then
    local info     = result.rows[1][1]
    -- calc max_size
    local max_size = 0
    for _, size in pairs(info) do
      if size > max_size then max_size = size end
    end
    if max_size > 1024 * 1024 * 1024 then
      -- humanize info
      local humanize_info = {}
      for slot_name, size in pairs(info) do
        local size_string        = humanize.ibytes(size)
        humanize_info[slot_name] = size_string
      end
      local jsonb      = {
        host           = host,
        key            = key,
        created_at     = get_last_created_at(host, key, unix_ts),
        custom_details = humanize_info,
      }
      local jsonb, err = json.encode(jsonb)
      if err then error(err) end
      storage:insert_metric({ host = host, plugin = plugin_name, json = jsonb })
    end
  end
end

return check
