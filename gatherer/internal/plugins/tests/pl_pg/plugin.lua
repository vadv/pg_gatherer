agent:query("select 1")
manager:insert_metric({plugin="test_pg", int=10})

time.sleep(1000)