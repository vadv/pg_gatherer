local uptime_metric_exists = function()
  return (metric_exists('pg.uptime') and metric_exists('pg.uptime.checkpointer'))
end

run_plugin_test(120, uptime_metric_exists)