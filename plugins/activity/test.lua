target:background_query("select pg_sleep(120)")

local activity_metric_exists = function()
  return (
          metric_exists('pg.activity')
          and metric_exists('pg.activity.states')
          and metric_exists('pg.activity.waits')
  )
end

run_plugin_test(120, activity_metric_exists)
prometheus_exists('pg.activity.states')
