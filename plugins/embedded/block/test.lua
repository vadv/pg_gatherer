local time = require("time")

connection:background_query("select pg_advisory_xact_lock(1), pg_sleep(10);")
connection:background_query("select pg_advisory_xact_lock(1), pg_sleep(10);")

plugin:create()
local timeout = 10
while timeout > 0 do
  if plugin:error_count() > 0 then error(plugin:last_error()) end
  time.sleep(1)
  timeout = timeout - 1
end
plugin:remove()

-- pg.block
local count = connection:query([[
select
  count(*)
from
  metric m
where
  plugin = md5('pg.block')::uuid
  and ts > extract( epoch from (now()-'1 minute'::interval) )
]]).rows[1][1]
if count == 0 then error('pg.block') end