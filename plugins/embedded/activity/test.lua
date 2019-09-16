-- ?
test:query_result_eq("select count(*) metric where md5('pg.activity')::uuid", 0);