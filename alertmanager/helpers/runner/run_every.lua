local time = require('time')
local inspect = require('inspect')

-- run function f every sec
local function run_every(f, every)
  while true do
    local start_at = time.unix()
    f()
    local sleep_time = every - (time.unix() - start_at)
    if sleep_time > 0 then
      time.sleep(sleep_time)
    else
      print(debug.getinfo(2).source, "execution timeout:", (time.unix() - start_at))
      time.sleep(1)
    end
  end
end

return run_every
