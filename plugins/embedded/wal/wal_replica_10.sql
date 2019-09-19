select
  pg_wal_lsn_diff(pg_last_wal_replay_lsn(), '0/00000000')::bigint     as wal_position,
  pg_catalog.pg_is_in_recovery()                                      as pg_is_in_recovery,
  extract(epoch from now() - pg_last_xact_replay_timestamp())::float8 as time_lag;