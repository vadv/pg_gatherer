local data = secrets_2:get("set_after_reload")
if not(data == "ok") then error("data: "..tostring(data)) end