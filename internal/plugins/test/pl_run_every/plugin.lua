local count_of_start = cache:get("key")
if not(count_of_start) then count_of_start = 1 end

function collect()
  time.sleep(1)

  if count_of_start == 1 then
    cache:set("key", count_of_start+1)
    error("first error")
  end

  if count_of_start == 2 then
    error("must not be this error")
  end

  cache:set("key", count_of_start+1)
end

run_every(collect, 10)