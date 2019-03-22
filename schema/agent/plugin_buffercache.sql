create extension if not exists pg_buffercache ;
drop function if exists gatherer.pg_buffer_cache_uses;
create function gatherer.pg_buffer_cache_uses() returns setof jsonb AS $$
    set local work_mem to '128MB';
    select
        jsonb_build_object(
          'full_relation_name', current_database() || '.' || n.nspname || '.' || c.relname,
          'relation_type', CASE c.relkind
            WHEN 'r' THEN 'table'
            WHEN 'v' THEN 'view'
            WHEN 'm' THEN 'materialized view'
            WHEN 'i' THEN 'index'
            WHEN 'S' THEN 'sequence'
            WHEN 's' THEN 'special'
            WHEN 'f' THEN 'foreign table'
            WHEN 'p' THEN 'table'
            WHEN 'I' THEN 'index'
          END,
          'buffers', count(b.*),
          'usagecount', b.usagecount,
          'dirty', b.isdirty
        ) as result
    from
      pg_buffercache b
      inner join pg_catalog.pg_class c on b.relfilenode = pg_relation_filenode(c.oid)
      left join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      group by c.relname, n.nspname, b.usagecount, b.isdirty, c.relkind
$$ language 'sql' security definer;
