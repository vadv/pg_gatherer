local http = require("http")

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
  and host = md5('%s')::uuid
  and ts > extract( epoch from (now()-'3 minute'::interval) )
  and (value_jsonb::text <> '{}' or value_jsonb is null)
  ]], metric, tested_plugin:host())
  local result = target:query(sql_query).rows[1]
  if result and result[1] then
    return result[1] > 0
  end
  return false
end

function plugin_check_error()
  if tested_plugin:error_count() > 0 then
    error(tested_plugin:last_error())
  end
end

function run_plugin_test(timeout, success_exit_function, check_error_function)
  check_error_function = check_error_function or plugin_check_error
  success_exit_function = success_exit_function or function() return false end
  tested_plugin:create()
  timeout = timeout or 120
  while timeout > 0 do
    check_error_function()
    if success_exit_function() then
      tested_plugin:remove()
      return
    end
    time.sleep(1)
    timeout = timeout - 1
  end
  tested_plugin:remove()
  error("execution timeout")
end

local http_listen = os.getenv("HTTP_LISTEN")
local client = http.client()
local request = http.request("GET", "http://"..http_listen.."/metrics")
function prometheus_exists(value)
  local result, err = client:do_request(request)
  if err then error(err) end
  if not(result.code == 200) then error("code: "..tostring(result.code)) end
  if strings.contains(result.body, value) then return end
  error(value.. ": not found in: "..tostring(result.body))
end
