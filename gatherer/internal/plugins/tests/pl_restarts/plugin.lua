print("plugin restarts was started")

local count_of_start = cache:get("key")
if not(count_of_start) then count_of_start = 1 end
print("restarts count_of_start: ", count_of_start)

if count_of_start == 2 then
  local stop_err = cache:get("stop_key")
  if not(stop_err) then
    cache:set("stop_key", 1)
    cache:set("key", count_of_start+1)
    error("error anchor-test-restarts")
  end
end

if count_of_start == 3 then
  time.sleep(1000)
end

cache:set("key", count_of_start+1)