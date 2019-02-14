create or replace function gatherer.pg_stat_user_tables() returns setof jsonb AS $$
    select
        jsonb_build_object(
          'relid', relid::bigint,
          'full_table_name', schemaname || '.' || relname,
          'last_vacuum', extract(epoch from last_vacuum)::bigint,
          'last_autovacuum', extract(epoch from last_autovacuum)::bigint,
          'last_analyze', extract(epoch from last_analyze)::bigint,
          'last_autoanalyze', extract(epoch from last_autoanalyze)::bigint,
          'vacuum_count', vacuum_count,
          'autovacuum_count', autovacuum_count,
          'analyze_count', analyze_count,
          'autoanalyze_count', autoanalyze_count,
          'seq_scan', seq_scan,
          'seq_tup_read', seq_tup_read,
          'idx_scan', idx_scan,
          'idx_tup_fetch', idx_tup_fetch,
          'n_tup_ins', n_tup_ins,
          'n_tup_upd', n_tup_upd,
          'n_tup_del', n_tup_del,
          'n_tup_hot_upd', n_tup_hot_upd,
          'n_live_tup', n_live_tup,
          'n_dead_tup', n_dead_tup,
          'n_mod_since_analyze', n_mod_since_analyze
        ) as result
    from
      pg_catalog.pg_stat_user_tables;
$$ language 'sql' security definer;
