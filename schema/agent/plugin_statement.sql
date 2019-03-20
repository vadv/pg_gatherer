create extension if not exists pg_stat_statements ;
drop function if exists gatherer.pg_stat_statements;
create function gatherer.pg_stat_statements() returns setof jsonb AS $$
    select
        jsonb_build_object(
          'current_database', current_database(),
          'queryid', queryid::bigint,
          'dbname', d.datname::text,
          'user', pg_catalog.pg_get_userbyid(userid)::text,
          'query', query::text,
          'calls', calls::bigint,
          'total_time', total_time::float8,
          'rows', rows::bigint,
          'shared_blks_hit', shared_blks_hit::bigint,
          'shared_blks_read', shared_blks_read::bigint,
          'shared_blks_written', shared_blks_written::bigint,
          'local_blks_hit', local_blks_hit::bigint,
          'local_blks_read', local_blks_read::bigint,
          'local_blks_dirtied', local_blks_dirtied::bigint,
          'local_blks_written', local_blks_written::bigint,
          'temp_blks_read', temp_blks_read::bigint,
          'temp_blks_written', temp_blks_written::bigint,
          'blk_read_time', blk_read_time::float8,
          'blk_write_time', blk_write_time::float8
        ) as result
    from
      pg_stat_statements s
      inner join pg_database d on s.dbid = d.oid;
$$ language 'sql' security definer;
