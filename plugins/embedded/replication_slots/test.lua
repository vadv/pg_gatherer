local time = require("time")

plugin:create()
local timeout = 10
while timeout > 0 do
  if plugin:error_count() > 0 then error(plugin:last_error()) end
  time.sleep(1)
  timeout = timeout - 1
end
plugin:remove()

-- pg.replication_slots
local count = connection:query([[
select
  count(*)
from
  metric m
where
  plugin = md5('pg.replication_slots')::uuid
  and ts > extract( epoch from (now()-'3 minute'::interval) )
]]).rows[1][1]
if count == 0 then error('pg.replication_slots') end