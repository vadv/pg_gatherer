select
  extract(epoch from (current_timestamp - pg_catalog.pg_postmaster_start_time()))::bigint;