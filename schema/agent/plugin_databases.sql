create or replace function gatherer.pg_databases() returns setof jsonb AS $$
    select
        jsonb_build_object(
          'datname', d.datname::text,
          'size', pg_catalog.pg_database_size(d.datname)::bigint,
          'age', age(s.datfrozenxid)::bigint,
          'numbackends', d.numbackends,
          'xact_commit', d.xact_commit,
          'xact_rollback', d.xact_rollback,
          'blks_read', d.blks_read,
          'blks_hit', d.blks_hit,
          'tup_returned', d.tup_returned,
          'tup_fetched', d.tup_fetched,
          'tup_inserted', d.tup_inserted,
          'tup_updated', d.tup_updated,
          'tup_deleted', d.tup_deleted,
          'conflicts', d.conflicts,
          'temp_files', d.temp_files,
          'temp_bytes', d.temp_bytes,
          'deadlocks', d.deadlocks,
          'blk_read_time', d.blk_read_time,
          'blk_write_time', d.blk_write_time
        ) as result
    from
        pg_catalog.pg_stat_database d
        inner join pg_catalog.pg_database s on s.datname = d.datname;
$$ language 'sql' security definer;
