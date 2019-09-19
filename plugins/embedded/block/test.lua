connection:background_query("select pg_advisory_xact_lock(1), pg_sleep(10);")
connection:background_query("select pg_advisory_xact_lock(1), pg_sleep(10);")

run_plugin_test(120, function() return metric_exists('pg.block') end)
