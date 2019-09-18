local time = require("time")

plugin:create()
local bg_query = connection:background_query("select pg_sleep(10)")
while bg_query:is_running() do
  time.sleep(1)
end
plugin:remove()