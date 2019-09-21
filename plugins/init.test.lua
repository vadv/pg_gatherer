-- load init.lua
local filepath = require("filepath")
local root     = filepath.dir(debug.getinfo(1).source)
dofile(filepath.join(root, "init.lua"))

function metric_exists(metric)
  local sql_query = string.format([[
select
  count(*)
from
  metric m
where
  plugin = md5('%s')::uuid
  and ts > extract( epoch from (now()-'3 minute'::interval) )
  ]], metric)
  local count = target:query(sql_query).rows[1][1]
  return not(count == 0)
end

function plugin_check_error()
  if plugin:error_count() > 0 then
    error(plugin:last_error())
  end
end

function run_plugin_test(timeout, success_exit_function, check_error_function)
  check_error_function = check_error_function or plugin_check_error
  success_exit_function = success_exit_function or function() return false end
  plugin:create()
  timeout = 120 or timeout
  while timeout > 0 do
    check_error_function()
    if success_exit_function() then
        plugin:remove()
        return
    end
    time.sleep(1)
    timeout = timeout - 1
  end
  plugin:remove()
end
