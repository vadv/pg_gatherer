local dict = {
  critical = "critical",
  error    = "error",
  warning  = "warning",
  info     = "info",
}

local key_default = secrets:get("pagerduty_key_default")
local routing_keys = {
  default  = key_default,
  critical = secrets:get("pagerduty_key_critical") or key_default,
  error    = secrets:get("pagerduty_key_error") or key_default,
  warning  = secrets:get("pagerduty_key_warning") or key_default,
  info     = secrets:get("pagerduty_key_info") or key_default,
}

-- return routing
local function routing(host, alert_key, custom_details, created_at)
  return {severity=dict.critical, key=routing_keys[dict.critical]}
end

return routing
