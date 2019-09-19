local time = require("time")
local goos = require("goos")

HOST_DEV_DIR = os.getenv('HOST_DEV_DIR') or '/dev'
HOST_SYS_DIR = os.getenv('HOST_SYS_DIR') or '/sys'
HOST_PROC_DIR = os.getenv('HOST_PROC_DIR') or '/proc'

if not goos.stat(HOST_PROC_DIR..'/meminfo') then
  print('disabled plugin, because /proc/meminfo not found')
  return
end

plugin:create()
local timeout = 10
while timeout > 0 do
  if plugin:error_count() > 0 then error(plugin:last_error()) end
  time.sleep(1)
  timeout = timeout - 1
end
plugin:remove()

-- linux.memory
local count = connection:query([[
select
  count(*)
from
  metric m
where
  plugin = md5('linux.memory')::uuid
  and ts > extract( epoch from (now()-'3 minute'::interval) )
]]).rows[1][1]
if count == 0 then error('linux.memory') end