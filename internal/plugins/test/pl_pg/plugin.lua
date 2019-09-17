connection:query("select 1")
manager:metric({plugin="test_pg", int=10})

time.sleep(1000)