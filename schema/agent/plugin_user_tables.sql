drop function if exists gatherer.pg_stat_user_tables;
create function gatherer.pg_stat_user_tables() returns setof jsonb AS $$
    select
        jsonb_build_object(
          'relid', relid::bigint,
          'full_table_name', current_database() || '.' || p.schemaname || '.' || p.relname,
          'last_vacuum', extract(epoch from p.last_vacuum)::bigint,
          'last_autovacuum', extract(epoch from p.last_autovacuum)::bigint,
          'last_analyze', extract(epoch from p.last_analyze)::bigint,
          'last_autoanalyze', extract(epoch from p.last_autoanalyze)::bigint,
          'vacuum_count', p.vacuum_count,
          'autovacuum_count', p.autovacuum_count,
          'analyze_count', p.analyze_count,
          'autoanalyze_count', p.autoanalyze_count,
          'seq_scan', p.seq_scan,
          'seq_tup_read', p.seq_tup_read,
          'idx_scan', p.idx_scan,
          'idx_tup_fetch', p.idx_tup_fetch,
          'n_tup_ins', p.n_tup_ins,
          'n_tup_upd', p.n_tup_upd,
          'n_tup_del', p.n_tup_del,
          'n_tup_hot_upd', p.n_tup_hot_upd,
          'n_live_tup', p.n_live_tup,
          'n_dead_tup', p.n_dead_tup,
          'n_mod_since_analyze', p.n_mod_since_analyze,
          'relpages', c.relpages,
          'reltuples', c.reltuples
        ) as result
    from
      pg_catalog.pg_stat_user_tables p
      inner join pg_catalog.pg_class c on c.oid = p.relid;
$$ language 'sql' security definer;

drop function if exists gatherer.pg_statio_user_tables;
create function gatherer.pg_statio_user_tables() returns setof jsonb AS $$
    select
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
$$ language 'sql' security definer;
