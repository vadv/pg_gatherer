print("plugin cache was started")

local count_of_start = cache:get("key")
if not(count_of_start) then count_of_start = 1 end
print("cache count_of_start: ", count_of_start)

if count_of_start == 3 then
  time.sleep(1000)
end

cache:set("key", count_of_start+1)