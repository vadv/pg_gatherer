select
  pg_xlog_location_diff(pg_last_xlog_replay_location(), '0/00000000')::bigint as wal_position,
  pg_catalog.pg_is_in_recovery()                                              as pg_is_in_recovery,
  extract(epoch from now() - pg_last_xact_replay_timestamp())::float8         as time_lag;