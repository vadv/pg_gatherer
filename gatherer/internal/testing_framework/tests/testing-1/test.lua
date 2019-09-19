local time = require("time")

plugin:create()
time.sleep(3)
if not(plugin:error_count() == 0) then
  error("error count: "..tostring(plugin:error_count()))
end

plugin:remove()