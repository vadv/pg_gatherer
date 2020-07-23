local prometheus = require("prometheus")
local gauge      = prometheus.gauge({ name = "name", namespace = "namespace", subsystem = "gauge", help = "" })

gauge:set(1)
prometheus_exists("\nnamespace_gauge_name 1\n")
gauge:inc()
prometheus_exists("\nnamespace_gauge_name 2\n")
gauge:add(2)
prometheus_exists("\nnamespace_gauge_name 4\n")
