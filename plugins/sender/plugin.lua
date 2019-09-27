local processors     = {}
processors.telegram  = dofile(filepath.join(plugin:dir(), "telegram.lua"))
processors.pagerduty = dofile(filepath.join(plugin:dir(), "pagerduty.lua"))

local sql            = read_file_in_plugin_dir("list_of_alerts.sql")

function process()
  local result = storage:query("select name from host where not maintenance")
  for _, rowHost in pairs(result.rows) do
    local host   = rowHost[1]
    local result = storage:query(sql, host, get_unix_ts(storage))
    for _, row in pairs(result.rows) do
      local alert = {
        key        = row[1], ts = row[2],
        host       = row[3], custom_details = row[4],
        created_at = row[5]
      }
      for name, process_f in pairs(processors) do
        local status, err = pcall(process_f, alert)
        if not status then
          plugin_log:printf("[ERROR] plugin '%s' processor '%s' error: %s\n", plugin:name(), name, err)
        end
      end
    end
  end
end

run_every(process, 5)
