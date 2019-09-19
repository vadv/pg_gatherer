local user_tables_metric_exists = function()
  return (metric_exists('pg.user_tables') and metric_exists('pg.user_tables.io'))
end

run_plugin_test(120, user_tables_metric_exists)