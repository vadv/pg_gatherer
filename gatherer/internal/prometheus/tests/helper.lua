http          = require("http")
strings        = require("strings")
local client  = http.client()
local request = http.request("GET", "http://127.0.0.1:9091/metrics")

function prometheus_exists(value)
  local result, err = client:do_request(request)
  if err then error(err) end
  if not (result.code == 200) then error("code: " .. tostring(result.code)) end
  if strings.contains(result.body, value) then return end
  error(value .. ": not found in: " .. tostring(result.body))
end
