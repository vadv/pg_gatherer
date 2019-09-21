local time = require("time")

tested_plugin:create()
time.sleep(3)
if not (tested_plugin:error_count() == 0) then
  error("error count: " .. tostring(tested_plugin:error_count()))
end

tested_plugin:remove()