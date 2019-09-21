if not(plugin_status:name() == "pl_stat") then
  error("name")
end

if not(plugin_status:start_count() == 1) then
  error("start_count: "..tostring(plugin_status:start_count()))
end

if not(plugin_status:error_count() == 0) then
  error("err_count: "..tostring(plugin_status:error_count()))
end

time.sleep(10000)