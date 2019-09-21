select
  extract(epoch from now())::int - (extract(epoch from now())::int % $1),
  jsonb_build_object(
      'current_database', current_database(),
      'full_relation_name', current_database() || '.' || n.nspname || '.' || c.relname,
      'relation_type', case c.relkind
                         when 'r' then 'table'
                         when 'v' then 'view'
                         when 'm' then 'materialized view'
                         when 'i' then 'index'
                         when 'S' then 'sequence'
                         when 's' then 'special'
                         when 'f' then 'foreign table'
                         when 'p' then 'table'
                         when 'I' then 'index'
        end,
      'buffers', count(b.*),
      'usagecount', b.usagecount,
      'dirty', b.isdirty
    ) as result
from
  pg_buffercache b
  inner join pg_catalog.pg_database d on d.oid = b.reldatabase and d.datname = current_database()
  left join pg_catalog.pg_class c on b.relfilenode = pg_relation_filenode(c.oid)
  left join pg_catalog.pg_namespace n on n.oid = c.relnamespace
group by
  c.relname, n.nspname, b.usagecount, b.isdirty, c.relkind