local time = require("time")

plugin:create()
local bg_query = connection:background_query("select pg_sleep(60)")
while bg_query:is_running() do
  if plugin:error_count() > 0 then error(plugin:last_error()) end
  time.sleep(1)
end
plugin:remove()