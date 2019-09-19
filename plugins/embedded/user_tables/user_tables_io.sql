select
    extract(epoch from now())::int - (extract(epoch from now())::int % $1),
    jsonb_build_object(
        'relid', relid::bigint,
        'full_table_name', current_database() || '.' || schemaname || '.' || relname,
        'heap_blks_read', heap_blks_read,
        'heap_blks_hit', heap_blks_hit,
        'idx_blks_read', idx_blks_read,
        'idx_blks_hit', idx_blks_hit,
        'toast_blks_read', toast_blks_read,
        'toast_blks_hit', toast_blks_hit,
        'tidx_blks_read', tidx_blks_read,
        'tidx_blks_hit', tidx_blks_hit
      ) as result
from
  pg_catalog.pg_statio_user_tables;