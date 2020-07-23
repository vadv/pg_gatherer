local prometheus   = require("prometheus")

local counter, err = prometheus_gauge({ name = "name", namespace = "namespace", subsystem = "counter", help = "" })
if err then error(err) end
counter:inc()
prometheus_exists("\nnamespace_counter_name 1\n")

local counter, err = prometheus_gauge({ name = "name", namespace = "namespace", subsystem = "counter", help = "" })
if err then error(err) end
counter:add(2)
prometheus_exists("\nnamespace_counter_name 3\n")
