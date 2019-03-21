create extension if not exists pg_buffercache ;
drop function if exists gatherer.pg_buffer_cache_uses;
create function gatherer.pg_buffer_cache_uses() returns setof jsonb AS $$
    select
        jsonb_build_object(
          'full_table_name', current_database() || '.' || n.nspname || '.' || c.relname,
          'buffers', count(b.*),
          'usagecount', b.usagecount,
          'dirty', b.isdirty
        ) as result
    from
      pg_buffercache b
      inner join pg_catalog.pg_class c on b.relfilenode = pg_relation_filenode(c.oid)
      left join pg_catalog.pg_namespace n on n.oid = c.relnamespace
      group by c.relname, n.nspname, b.usagecount, b.isdirty
$$ language 'sql' security definer;
