if not (plugin:name() == "pl_stat") then
  error("name")
end

if not (plugin:start_count() == 1) then
  error("start_count: " .. tostring(plugin:start_count()))
end

if not (plugin:error_count() == 0) then
  error("err_count: " .. tostring(plugin:error_count()))
end

time.sleep(10000)