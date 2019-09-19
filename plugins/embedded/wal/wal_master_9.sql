select
  pg_xlog_location_diff(pg_current_xlog_location(), '0/00000000')::bigint as wal_position,
  pg_catalog.pg_is_in_recovery()                                          as pg_is_in_recovery,
  0::float8                                                               as time_lag;