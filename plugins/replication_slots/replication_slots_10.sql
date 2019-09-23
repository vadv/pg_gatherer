select
  s.slot_name::text as slot_name,
  pg_catalog.pg_wal_lsn_diff(pg_catalog.pg_current_wal_lsn(), s.restart_lsn)::bigint as size
from
  pg_catalog.pg_replication_slots s;