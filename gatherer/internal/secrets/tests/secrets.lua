local data = secrets_1:get("unknown")
if data then error("must be nil") end

local data = secrets_1:get("test_1")
if not(data == "ok") then error("data: "..tostring(data)) end
