local time = require("time")

plugin:create()
local bg_query = connection:background_query("select pg_sleep(120)")
while bg_query:is_running() do
  if plugin:error_count() > 0 then error(plugin:last_error()) end
  time.sleep(1)
end
plugin:remove()

-- pg.activity
local count = connection:query([[
select
  count(*)
from
  metric m
where
  plugin = md5('pg.activity')::uuid
  and ts > extract( epoch from (now()-'2 minute'::interval) )
]]).rows[1][1]
if count == 0 then error('pg.activity') end

-- pg.activity.states
local count = connection:query([[
select
  count(*)
from
  metric m
where
  plugin = md5('pg.activity.states')::uuid
  and ts > extract( epoch from (now()-'2 minute'::interval) )
]]).rows[1][1]
if count == 0 then error('pg.activity.states') end

-- pg.activity.waits
local count = connection:query([[
select
  count(*)
from
  metric m
where
  plugin = md5('pg.activity.waits')::uuid
  and ts > extract( epoch from (now()-'2 minute'::interval) )
]]).rows[1][1]
if count == 0 then error('pg.activity.waits') end