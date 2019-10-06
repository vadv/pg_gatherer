{
    stat_uptime:: |||
 select
   time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
   max(value_bigint)
 from
   metric
 where
   $__unixEpochFilter(ts)
   and host = md5('$host')::uuid
   and plugin = md5('pg.uptime')::uuid
 group by 1
 order by 1;
|||,
    stat_size:: |||
 with data as (
  select
    snapshot                                           as ts,
    sum(coalesce((value_jsonb ->> 'size')::float8, 0)) as value
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.databases')::uuid
  group by 1
  order by 1
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data
 group by 1
 order by 1
|||,
  stat_wal:: |||
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value_double)                                                         as value
 from
  metric
 where
   $__unixEpochFilter(ts)
   and host = md5('$host')::uuid
   and plugin = md5('pg.wal.speed')::uuid
 group by 1
 order by 1
|||,
  stat_repl_lag:: |||
 select
  ts           as time,
  value_double as value
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.wal.replication_time_lag')::uuid
|||,
   stat_repl_slot:: |||
 with slots as (
  select distinct
    (jsonb_object_keys(value_jsonb)) as name
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.replication_slots')::uuid
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  max(coalesce((m.value_jsonb ->> (s.name))::bigint, 0))                    as value
 from
  metric m,
  slots s
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.replication_slots')::uuid
 group by 1
 order by 1
|||,
  stat_buff_poll_hit_rate: |||
 with data as (
  select
    ts,
    sum(coalesce((value_jsonb ->> 'blks_hit')::float8, 0)) /
    (1 + sum(coalesce((value_jsonb ->> 'blks_read')::float8, 0)) +
     sum(coalesce((value_jsonb ->> 'blks_hit')::float8, 0))) as value
  from
    metric
  where
    $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.databases')::uuid
  group by ts
  order by ts
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data
 group by 1
 order by 1
|||,
  stat_tps: |||
 with data as (select
                snapshot                                                    as ts,
                sum(coalesce((value_jsonb ->> 'xact_commit')::float8, 0) +
                    coalesce((value_jsonb ->> 'xact_rollback')::float8, 0)) as value
              from
                metric
              where
                $__unixEpochFilter(ts)
                and host = md5('$host')::uuid
                and plugin = md5('pg.databases')::uuid
              group by 1
              order by 1)
   , data2 as (select
                 ts,
                 sum(value) as value
               from
                 data
               group by 1
               order by 1)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data2
 group by 1
 order by 1
|||,
  stat_qps: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.statements')::uuid)
   , data2 as (select
                 snapshot                               as ts,
                 sum((value_jsonb ->> 'calls')::bigint) as value
               from
                 data
               group by snapshot
               order by snapshot)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  (value) / (ts - lag(ts) over w)                                           as qps
 from
  data2
 window w as (order by ts)
 order by 1
|||,
  stat_errors: |||
 with data as (
  select
    snapshot                                       as ts,
    sum((value_jsonb ->> 'xact_rollback')::float8) as value
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.databases')::uuid
  group by snapshot
  order by snapshot)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data
 group by 1
 order by 1
|||,
  stat_queries_avg: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.statements')::uuid
 ),
     data2 as (
       select
         snapshot                                                  as ts,
         sum(coalesce((value_jsonb ->> 'total_time')::float8, 0)) /
         (sum(coalesce((value_jsonb ->> 'calls')::float8, 0)) + 1) as value
       from
         data
       group by snapshot
       order by snapshot
     )
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data2
 group by 1
 order by 1
|||,
  stat_long_query: |||
 select
  time_bucket('"$interval"'::interval, to_timestamp(snapshot) at time zone 'UTC') as time,
  max(coalesce((value_jsonb ->> 'query_start_duration')::bigint, 0))
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.activity')::uuid
  and not value_jsonb->>'query' ~ '^autovacuum: '
 group by 1
 order by 1;
|||,
    stat_idle_in_tx: |||
 with data as (select
                snapshot                                            as ts,
                sum(coalesce((value_jsonb ->> 'count')::float8, 0)) as value
              from
                metric
              where
                $__unixEpochFilter(ts)
                and host = md5('$host')::uuid
                and plugin = md5('pg.activity.waits')::uuid
                and value_jsonb->>'state' = 'idle in transaction'
              group by snapshot
              order by snapshot)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data
 group by 1
 order by 1
|||,
  stat_waiting: |||
 with data as (select
                snapshot                               as ts,
                sum((value_jsonb ->> 'count')::float8) as value
              from
                metric
              where
                $__unixEpochFilter(ts)
                and host = md5( '$host')::uuid
                and plugin = md5('pg.activity.waits')::uuid
                and value_jsonb->>'state' <> 'idle in transaction'
              group by snapshot
              order by snapshot)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data
 group by 1
 order by 1
|||,
  stat_seq_scans: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
   , data2 as (select
                 snapshot                                               as ts,
                 sum(coalesce((value_jsonb ->> 'seq_scan')::float8, 0)) as value
               from
                 data
               where
                   coalesce((value_jsonb ->> 'relpages')::bigint, 0) > (256 * 1024 * 1024) / (8 * 1024)
               group by snapshot
               order by snapshot)
   , data3 as (select
                 ts,
                 (value) / (ts - lag(ts) over w) as value_per_second
               from
                 data2
                 window w as (order by ts)
               order by 1)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value_per_second)
 from
  data3
 group by 1
 order by 1
|||,
  stat_bloat: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
 select
  snapshot as time,
  sum(coalesce((value_jsonb ->> 'n_dead_tup')::bigint, 0)) / sum(coalesce((value_jsonb ->> 'n_live_tup')::bigint, 0))
 from
  data
 where
  (value_jsonb ->> 'n_live_tup')::bigint > 0
 group by 1
 order by 1
|||,
  stat_dirty: |||
 with dirty as (
  select
    m.snapshot                                                             as time,
    sum(COALESCE((m.value_jsonb ->> 'dirty_count')::bigint, 0) * 8 * 1024) as size
  from
    metric m
  where
    $__unixEpochFilter(m.ts)
    and m.host = md5('$host')::uuid
    and m.plugin = md5('pg.buffercache')::uuid
  group by 1
  order by 1
 )
   , total as (
  select
    m.snapshot                                                               as time,
    sum(COALESCE((m.value_jsonb ->> 'buffers_count')::bigint, 0) * 8 * 1024) as size
  from
    metric m
  where
    $__unixEpochFilter(m.ts)
    and m.host = md5('$host')::uuid
    and m.plugin = md5('pg.buffercache')::uuid
  group by 1
  order by 1
 )
   , data as (select
                total.time                      as ts,
                (dirty.size / (total.size + 1)) as value
              from
                total
                inner join dirty on dirty.time = total.time)
   , data2 as (select
                 ts,
                 sum(value) as value
               from
                 data
               group by 1
               order by 1)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data2
 group by 1
 order by 1
|||,
  stat_buffer_reuse: |||
 with usage_count_0 as (
  select
    m.snapshot                                                               as time,
    sum(COALESCE((m.value_jsonb ->> 'usage_count_0')::bigint, 0) * 8 * 1024) as size
  from
    metric m
  where
    $__unixEpochFilter(m.ts)
    and m.host = md5('$host')::uuid
    and m.plugin = md5('pg.buffercache')::uuid
  group by 1
  order by 1
 ),
     total as (
       select
         m.snapshot                                                               as time,
         sum(COALESCE((m.value_jsonb ->> 'buffers_count')::bigint, 0) * 8 * 1024) as size
       from
         metric m
       where
         $__unixEpochFilter(
         m.ts)
       and
         m.host = md5(
         '$host')::uuid
       and
         m.plugin = md5(
         'pg.buffercache')::uuid
       group by 1
       order by 1
     )
    ,
     data as (
       select
         total.time                                  as ts,
         1 - (usage_count_0.size / (total.size + 1)) as value
       from
         total
         inner join usage_count_0 on usage_count_0.time = total.time
     )
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value)
 from
  data
 group by 1
 order by 1
|||,
  row_databases: |||
 select
  value_jsonb ->> 'datname'                                                                           as name,
  pg_catalog.pg_size_pretty((max(value_jsonb ->> 'size')::bigint))                                    as size,
  max((value_jsonb ->> 'age')::bigint)                                                                as age,
  sum((value_jsonb ->> 'conflicts')::float8)                                                          as conflicts,
  sum((value_jsonb ->> 'temp_files')::float8)                                                         as "temp files",
  TO_CHAR((sum((value_jsonb ->> 'blk_read_time')::float8) * interval '1 millisecond'), 'HH24:MI:SS')  as "read time",
  TO_CHAR((sum((value_jsonb ->> 'blk_write_time')::float8) * interval '1 millisecond'), 'HH24:MI:SS') as "write time",
  round(max((value_jsonb ->> 'xact_commit')::numeric), 2)                                             as "commits/s",
  round(max((value_jsonb ->> 'xact_rollback')::numeric), 2)                                           as "rollback/s"
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.databases')::uuid
 group by 1
 order by 1
|||,
  row_tables_big: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
 select
  value_jsonb ->> 'full_table_name'                                                                        as table,
  max((value_jsonb ->> 'relpages')::bigint) * 8 * 1024                                                     as size,
  max((value_jsonb ->> 'reltuples')::bigint)                                                               as rows,
  round(100 * max((value_jsonb ->> 'n_dead_tup')::float8) /
        (max((value_jsonb ->> 'n_dead_tup')::float8) + max((value_jsonb ->> 'n_live_tup')::float8))) /
  100                                                                                                      as "rows % deleted",
  round(100 * max((value_jsonb ->> 'n_live_tup')::float8) /
        (max((value_jsonb ->> 'n_dead_tup')::float8) + max((value_jsonb ->> 'n_live_tup')::float8))) /
  100                                                                                                      as "rows % live"
 from
  data
 group by 1
 having (max((value_jsonb ->> 'n_dead_tup')::float8) + max((value_jsonb ->> 'n_live_tup')::float8)) > 0
 order by 2 desc
 limit 20;
|||,
    row_tables_change: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
 select
  value_jsonb ->> 'full_table_name'                                                       as table,
  max((value_jsonb ->> 'relpages')::bigint) * 8 * 1024                                    as "size max",
  min((value_jsonb ->> 'relpages')::bigint) * 8 * 1024                                    as "size min",
  max((value_jsonb ->> 'reltuples')::bigint)                                              as "rows max",
  min((value_jsonb ->> 'reltuples')::bigint)                                              as "rows min",
  max((value_jsonb ->> 'reltuples')::bigint) - min((value_jsonb ->> 'reltuples')::bigint) as "rows changed"
 from
  data
 group by 1
 order by max((value_jsonb ->> 'reltuples')::bigint) - min((value_jsonb ->> 'reltuples')::bigint) desc, 2 desc
 limit 20;
|||,
    row_backend_states: |||
 with data as (select
  snapshot as ts,
  --  avg( (value_jsonb->>'idle')::int ) as "idle",
  sum((value_jsonb ->> 'active')::int)                        as active,
  sum((value_jsonb ->> 'idle in transaction')::int)           as "idle in transaction",
  sum((value_jsonb ->> 'idle in transaction (aborted)')::int) as "idle in transaction (aborted)",
  sum((value_jsonb ->> 'fastpath function call')::int)        as "fastpath function call"
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.activity.states')::uuid
 group by 1
 order by 1
 )
 select
   time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
   avg(active) as active,
   avg("idle in transaction") as "idle in transaction",
   avg("idle in transaction (aborted)") as "idle in transaction (aborted)",
   avg("fastpath function call") as "fastpath function call"
 from data
 group by 1
 order by 1
|||,
  row_backend_wait_event_type: |||
 with wait_event_type as (select
   distinct(m.value_jsonb ->> 'wait_event_type') as wait_event_type
  from
    metric m
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.activity.waits')::uuid
 )
 , snapshots as (select
   distinct(snapshot) as snapshot
  from
    metric m
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.activity.waits')::uuid
 )
 , data as (select
    s.snapshot,
    t.wait_event_type
   from snapshots s, wait_event_type t
 )
 , data2 as (select
    d.snapshot        as ts,
    d.wait_event_type as type,
    case
     when
       m.value_jsonb->>'wait_event_type' = d.wait_event_type
     then
       (m.value_jsonb->>'count')::bigint
     else
       0
    end as value
  from
    data d
    left join metric m on m.snapshot = d.snapshot
  where
    $__unixEpochFilter(m.ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.activity.waits')::uuid
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  type,
  avg(value)
 from
  data2
 group by 1,2
 order by 1,2
|||,
  row_backend_wait_events: |||
 with wait_event_type as (select
   distinct(m.value_jsonb ->> 'wait_event') as wait_event
  from
    metric m
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.activity.waits')::uuid
 )
 , snapshots as (select
   distinct(snapshot) as snapshot
  from
    metric m
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.activity.waits')::uuid
 )
 , data as (select
    s.snapshot,
    t.wait_event
   from snapshots s, wait_event_type t
 )
 , data2 as (select
    d.snapshot   as ts,
    d.wait_event as type,
    case
     when
       m.value_jsonb->>'wait_event' = d.wait_event
     then
       (m.value_jsonb->>'count')::bigint
     else
       0
    end as value
  from
    data d
    left join metric m on m.snapshot = d.snapshot
  where
    $__unixEpochFilter(m.ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.activity.waits')::uuid
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  type,
  avg(value)
 from
  data2
 group by 1,2
 order by 1,2
|||,
  row_operations_queries: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.statements')::uuid
 )
   , data2 as (select
                 snapshot                               as ts,
                 sum((value_jsonb ->> 'calls')::float8) as value
               from
                 data
               group by snapshot
               order by snapshot)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  (value) / (ts - lag(ts) over w)                                           as qps
 from
  data2
  window w as (order by ts)
 order by 1
|||,
  row_operations_tx: |||
 with data as (select
                ts                                                          as ts,
                value_jsonb ->> 'datname'                                   as database,
                sum(coalesce((value_jsonb ->> 'xact_commit')::float8, 0) +
                    coalesce((value_jsonb ->> 'xact_rollback')::float8, 0)) as value
              from
                metric
              where
                $__unixEpochFilter(ts)
                and host = md5('$host')::uuid
                and plugin = md5('pg.databases')::uuid
              group by 1, 2
              order by ts)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  database,
  avg(value)
 from
  data
 group by 1,2
 order by 1,2
|||,
  row_statements_disk_read: |||
 with data as (
  select
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.statements')::uuid
 )
 select
  value_jsonb ->> 'dbname'                                    as database,
  value_jsonb ->> 'query'                                     as query,
  sum(coalesce((value_jsonb ->> 'calls')::bigint, 0))         as calls,
  sum(
        coalesce((value_jsonb ->> 'shared_blks_read')::float8, 0)
        + coalesce((value_jsonb ->> 'local_blks_read')::float8, 0)
        + coalesce((value_jsonb ->> 'temp_blks_read')::float8, 0)
    ) * 8 * 1024::bigint                                      as disk,
  sum(coalesce((value_jsonb ->> 'blk_read_time')::float8, 0)) as time
 from
  data
 group by 1,2
 having
    sum(
          coalesce((value_jsonb ->> 'shared_blks_read')::float8, 0)
          + coalesce((value_jsonb ->> 'local_blks_read')::float8, 0)
          + coalesce((value_jsonb ->> 'temp_blks_read')::float8, 0)
      ) > 0
 order by
  sum(
        coalesce((value_jsonb ->> 'shared_blks_read')::float8, 0)
        + coalesce((value_jsonb ->> 'local_blks_read')::float8, 0)
        + coalesce((value_jsonb ->> 'temp_blks_read')::float8, 0)
    )
|||,
  row_statements_disk_write: |||
 with data as (
  select
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.statements')::uuid
 )
 select
  value_jsonb ->> 'dbname'                                     as database,
  value_jsonb ->> 'query'                                      as query,
  sum(coalesce((value_jsonb ->> 'calls')::bigint, 0))          as calls,
  sum(
        coalesce((value_jsonb ->> 'shared_blks_written')::float8, 0)
        + coalesce((value_jsonb ->> 'local_blks_written')::float8, 0)
        + coalesce((value_jsonb ->> 'local_blks_dirtied')::float8, 0)
        + coalesce((value_jsonb ->> 'temp_blks_written')::float8, 0)
    ) * 8 / 1024::bigint                                       as disk,
  sum(coalesce((value_jsonb ->> 'blk_write_time')::float8, 0)) as time
 from
  data
 group by 1,2
 having
    sum(
          coalesce((value_jsonb ->> 'shared_blks_written')::float8, 0)
          + coalesce((value_jsonb ->> 'local_blks_written')::float8, 0)
          + coalesce((value_jsonb ->> 'local_blks_dirtied')::float8, 0)
          + coalesce((value_jsonb ->> 'temp_blks_written')::float8, 0)
      ) > 0
 order by
  sum(
        coalesce((value_jsonb ->> 'shared_blks_written')::float8, 0)
        + coalesce((value_jsonb ->> 'local_blks_written')::float8, 0)
        + coalesce((value_jsonb ->> 'local_blks_dirtied')::float8, 0)
        + coalesce((value_jsonb ->> 'temp_blks_written')::float8, 0)
    )
|||,
  row_statements_time: |||
 with data as (
  select
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.statements')::uuid
 )
 select
  value_jsonb ->> 'dbname'                                 as database,
  value_jsonb ->> 'query'                                  as query,
  sum(coalesce((value_jsonb ->> 'calls')::bigint, 0))      as calls,
  sum(coalesce((value_jsonb ->> 'total_time')::float8, 0)) as total_time
 from
  data
 where
    value_jsonb ->> 'query' <> 'BEGIN'
    and value_jsonb ->> 'query' <> 'BEGIN READ WRITE'
    and value_jsonb ->> 'query' <> 'COMMIT'
    and value_jsonb ->> 'query' <> 'ROLLBACK'
 group by 1,2
 order by sum(coalesce((value_jsonb ->> 'total_time')::float8, 0)) desc
 limit 20
|||,
    row_statements_temp_files: |||
 with data as (
  select
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.statements')::uuid
 )
 select
  value_jsonb ->> 'dbname' as database,
  value_jsonb ->> 'query'  as query,
  sum(
        coalesce((value_jsonb ->> 'temp_blks_written')::float8, 0)
        + coalesce((value_jsonb ->> 'temp_blks_read')::float8, 0)
    )::bigint * 8 * 1024   as size
 from
  data
 group by 1,2
 having
    sum(
          coalesce((value_jsonb ->> 'temp_blks_written')::float8, 0)
          + coalesce((value_jsonb ->> 'temp_blks_read')::float8, 0)
      ) > 0
 order by
  sum(
        coalesce((value_jsonb ->> 'temp_blks_written')::float8, 0)
        + coalesce((value_jsonb ->> 'temp_blks_read')::float8, 0)
    ) desc
 limit 20
|||,
    row_logged_statements_lock: |||
 select
  value_jsonb ->> 'database'                              as dbname,
  value_jsonb ->> 'blocked_statement'                     as blocked_statement,
  value_jsonb ->> 'current_statement_in_blocking_process' as current_statement_in_blocking_process,
  min(to_timestamp(ts) at time zone 'UTC')                as "first seen",
  max(to_timestamp(ts) at time zone 'UTC')                as "last seen",
  value_jsonb ->> 'blocked_query_id'                      as blocked_query_id,
  value_jsonb ->> 'blocking_query_id'                     as blocking_query_id,
  (max(ts) - min(ts))                                     as duration
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.block')::uuid
 group by 1, 2, 3, value_jsonb->>'blocked_query_id', value_jsonb->>'blocking_query_id'
 having (max(ts) - min (ts))> 1
  order by (max(ts) - min (ts)) desc
|||,
  row_logged_statements_long: |||
 select
  value_jsonb ->> 'datname'                      as datname,
  value_jsonb ->> 'query_id'                     as query_id,
  min(to_timestamp(ts) at time zone 'UTC')       as "first seen",
  max(to_timestamp(ts) at time zone 'UTC')       as "last seen",
  (max(ts) - min(ts))::bigint                    as duration,
  max(value_jsonb ->> 'query')                   as query,
  (max(value_jsonb ->> 'rchar')::float8)::bigint as read,
  (max(value_jsonb ->> 'wchar')::float8)::bigint as write,
  (max(value_jsonb ->> 'utime')::float8) / 100   as user,
  (max(value_jsonb ->> 'stime')::float8) / 100   as system
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.activity')::uuid
 group by 1, 2
 having max(ts) - min (ts) > 60
 order by max(value_jsonb->>'rchar')::float8 desc nulls last
|||,
  row_logged_statements_autovacuum: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
 select
  value_jsonb ->> 'full_table_name'                                                 as table,
  max(to_timestamp((value_jsonb ->> 'last_autovacuum')::bigint) at time zone 'UTC') as last_autovacuum,
  sum((value_jsonb ->> 'autovacuum_count')::bigint)                                 as "autovacuum count"
 from
  data
 group by 1
 having (sum((value_jsonb ->> 'autovacuum_count')::bigint) > 0)
 order by 2
|||,
  row_logged_statements_autoanalyze: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
 select
  value_jsonb ->> 'full_table_name'                                                  as table,
  max(to_timestamp((value_jsonb ->> 'last_autoanalyze')::bigint) at time zone 'UTC') as last_autoanalyze,
  sum((value_jsonb ->> 'autoanalyze_count')::bigint)                                 as "autoanalyze count"
 from
  data
 group by 1
 having (sum((value_jsonb ->> 'autoanalyze_count')::bigint) > 0)
 order by 2
|||,
  row_seq_scan: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
 select
  to_timestamp(snapshot)                                       as timestamp,
  value_jsonb ->> 'full_table_name'                            as table,
  coalesce((value_jsonb ->> 'relpages')::bigint, 0) * 8 * 1024 as "table size",
  sum(coalesce((value_jsonb ->> 'seq_scan')::float8, 0))       as count
 from
  data
 where
  coalesce((value_jsonb ->> 'relpages')::bigint, 0) > (256 * 1024 * 1024) / (8 * 1024)
  group by 1, 2, 3, snapshot
  having sum(coalesce((value_jsonb ->> 'seq_scan')::float8, 0)) > 0
  order by snapshot;
|||,
    row_buffer_pool_relation: |||
 with data as (
  select
    m.ts                                                         as time,
    j.key                                                        as relation,
    sum(coalesce((j.value ->> 'buffers')::bigint, 0) * 8 * 1024) as size
  from
    metric m
    cross join lateral jsonb_each((m.value_jsonb ->> 'per_relation_stat')::jsonb) j
  where
    $__unixEpochFilter(m.ts)
    and m.host = md5('$host')::uuid
    and m.plugin = md5('pg.buffercache')::uuid
  group by 1, 2
  order by 1, 2
 )
   , big_relations as (
  select
    d.relation  as relation,
    sum(d.size) as size
  from
    data d
  group by 1
  order by 2 desc
  limit 20
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(d.time) at time zone 'UTC') as time,
  d.relation,
  avg(d.size)
 from
  data d
  inner join big_relations t on t.relation = d.relation
 group by 1,2
 order by 1,2
|||,
  row_buffer_pool_dirty: |||
 with data as (
  select
    m.ts,
    sum(COALESCE((m.value_jsonb ->> 'dirty_count')::bigint, 0) * 8 * 1024) as dirty,
    m.value_jsonb ->> 'datname'                                            as database
  from
    metric m
  where
    $__unixEpochFilter(m.ts)
    and m.host = md5('$host')::uuid
    and m.plugin = md5('pg.buffercache')::uuid
  group by 1,3
  order by 1
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(d.ts) at time zone 'UTC') as time,
  avg(d.dirty),
  d.database
 from
  data d
 group by 1,3
 order by 1
|||,
  row_buffer_pool_usagecount_0: |||
 with data as (
  select
    m.ts                                                                     as time,
    sum(COALESCE((m.value_jsonb ->> 'usage_count_0')::bigint, 0) * 8 * 1024) as usage,
    m.value_jsonb ->> 'datname'                                              as database
  from
    metric m
  where
    $__unixEpochFilter(m.ts)
    and m.host = md5('$host')::uuid
    and m.plugin = md5('pg.buffercache')::uuid
  group by 1, m.value_jsonb->>'datname'
  order by 1
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(d.time) at time zone 'UTC') as time,
  avg(d.usage),
  d.database
 from
  data d
 group by 1,3
 order by 1,3
|||,
  row_buffer_pool_usagecount_3: |||
 with data as (
  select
    m.ts                                                                     as time,
    sum(COALESCE((m.value_jsonb ->> 'usage_count_3')::bigint, 0) * 8 * 1024) as usage,
    m.value_jsonb ->> 'datname'                                              as database
  from
    metric m
  where
    $__unixEpochFilter(m.ts)
    and m.host = md5('$host')::uuid
    and m.plugin = md5('pg.buffercache')::uuid
  group by 1, m.value_jsonb->>'datname'
  order by 1
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(d.time) at time zone 'UTC') as time,
  avg(d.usage),
  d.database
 from
  data d
 group by 1,3
 order by 1,3
|||,
  row_buffer_pool_database: |||
 with data as (
  select
    m.ts                                                                     as time,
    sum(COALESCE((m.value_jsonb ->> 'buffers_count')::bigint, 0) * 8 * 1024) as usage,
    m.value_jsonb ->> 'datname'                                              as database
  from
    metric m
  where
    $__unixEpochFilter(m.ts)
    and m.host = md5('$host')::uuid
    and m.plugin = md5('pg.buffercache')::uuid
  group by 1, m.value_jsonb->>'datname'
  order by 1)
 select
  time_bucket('"$interval"'::interval, to_timestamp(d.time) at time zone 'UTC') as time,
  avg(d.usage),
  d.database
 from
  data d
 group by 1,3
 order by 1,3
|||,
  row_table_seq_scan: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
   , tables as (
  select
    m.value_jsonb ->> 'full_table_name'                          as table,
    sum(coalesce((m.value_jsonb ->> 'seq_tup_read')::float8, 0)) as rows
  from
    data m
  group by 1
  order by 2 desc
  limit 20
 )
   , data2 as (select
                 snapshot                                                     as ts,
                 m.value_jsonb ->> 'full_table_name'                          as table,
                 sum(coalesce((m.value_jsonb ->> 'seq_tup_read')::float8, 0)) as value
               from
                 tables t
                 inner join data m on t.table = m.value_jsonb ->> 'full_table_name'
               group by 1, 2
               order by 1, 2)
   , data3 as (select
                 ts,
                 "table",
                 sum(value) as value
               from
                 data2
               group by 1, 2
               order by 1, 2)
   , data4 as (select
                 ts,
                 "table",
                 (value) / (ts - lag(ts) over (partition by "table" order by ts)) as value_per_second
               from
                 data3
               order by 1, 2)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  "table",
  avg(value_per_second)
 from
  data4
 group by 1,2
 order by 1,2
|||,
  row_table_index: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
   , tables as (
  select
    m.value_jsonb ->> 'full_table_name'                           as table,
    sum(coalesce((m.value_jsonb ->> 'idx_tup_fetch')::float8, 0)) as rows
  from
    data m
  group by 1
  order by 2 desc
  limit 20
 )
   , data2 as (select
                 m.snapshot                                                    as ts,
                 m.value_jsonb ->> 'full_table_name'                           as table,
                 sum(coalesce((m.value_jsonb ->> 'idx_tup_fetch')::float8, 0)) as value
               from
                 data m
                 inner join tables t on t.table = m.value_jsonb ->> 'full_table_name'
               group by 1, 2
               order by 1, 2)
   , data3 as (select
                 ts,
                 "table",
                 sum(value) as value
               from
                 data2
               group by 1, 2
               order by 1, 2)
   , data4 as (select
                 ts,
                 "table",
                 (value) / (ts - lag(ts) over (partition by "table" order by ts)) as value_per_second
               from
                 data3
               order by 1, 2)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  "table",
  avg(value_per_second)
 from
  data4
 group by 1,2
 order by 1,2
|||,
  row_table_changed: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables')::uuid
 )
   , tables as (
  select
    m.value_jsonb ->> 'full_table_name' as table,
    sum(coalesce((m.value_jsonb ->> 'n_tup_ins')::float8, 0) + coalesce((value_jsonb ->> 'n_tup_upd')::float8, 0) +
        coalesce((value_jsonb ->> 'n_tup_del')::float8, 0) + coalesce((value_jsonb ->> 'n_tup_hot_upd')::float8, 0))
  from
    data m
  group by 1
  order by 2 desc
  limit 20
 )
   , data2 as (select
                 m.snapshot                                                  as ts,
                 m.value_jsonb ->> 'full_table_name'                         as table,
                 sum(coalesce((m.value_jsonb ->> 'n_tup_ins')::float8, 0) +
                     coalesce((value_jsonb ->> 'n_tup_upd')::float8, 0) +
                     coalesce((value_jsonb ->> 'n_tup_del')::float8, 0) +
                     coalesce((value_jsonb ->> 'n_tup_hot_upd')::float8, 0)) as value
               from
                 data m
                 inner join tables t on t.table = m.value_jsonb ->> 'full_table_name'
               group by 1, 2
               order by 1, 2)
   , data3 as (select
                 ts,
                 "table",
                 sum(value) as value
               from
                 data2
               group by 1, 2
               order by 1, 2)
   , data4 as (select
                 ts,
                 "table",
                 (value) / (ts - lag(ts) over (partition by "table" order by ts)) as value_per_second
               from
                 data3
               order by 1, 2)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  "table",
  avg(value_per_second)
 from
  data4
 group by 1,2
 order by 1,2
|||,
    row_table_heap_read_bps: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables.io')::uuid
 )
 , tables as (
  select
    m.value_jsonb ->> 'full_table_name'                            as table,
    sum(coalesce((m.value_jsonb ->> 'heap_blks_read')::float8, 0)) as rows
  from
    data m
  group by 1
  order by 2 desc
  limit 20
 )
   , data2 as (
  select
    m.snapshot                                                                as ts,
    m.value_jsonb ->> 'full_table_name'                                       as table,
    sum(coalesce((m.value_jsonb ->> 'heap_blks_read')::float8, 0)) * 8 * 1024 as value
  from
    data m
    inner join tables t on t.table = m.value_jsonb ->> 'full_table_name'
  group by 1, 2
  order by 1)
   , data3 as (select
                 ts,
                 "table",
                 sum(value) as value
               from
                 data2
               group by 1, 2
               order by 1, 2)
   , data4 as (select
                 ts,
                 "table",
                 (value) / (ts - lag(ts) over (partition by "table" order by ts)) as value_per_second
               from
                 data3
               order by 1, 2)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  "table",
  avg(value_per_second)
 from
  data4
 group by 1,2
 order by 1,2
|||,
  row_table_index_read_bps: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables.io')::uuid
 )
   , tables as (
  select
    m.value_jsonb ->> 'full_table_name'                            as table,
    sum(coalesce((m.value_jsonb ->> 'tidx_blks_read')::float8, 0)) as rows
  from
    data m
  group by 1
  order by 2 desc
  limit 20
 )
 , data2 as (
  select
    m.snapshot                                                                as ts,
    m.value_jsonb ->> 'full_table_name'                                       as table,
    sum(coalesce((m.value_jsonb ->> 'tidx_blks_read')::float8, 0)) * 8 * 1024 as value
  from
    data m
    inner join tables t on t.table = m.value_jsonb ->> 'full_table_name'
  group by 1, 2
  order by 1
 )
   , data3 as (select
                 ts,
                 "table",
                 sum(value) as value
               from
                 data2
               group by 1, 2
               order by 1, 2)
   , data4 as (select
                 ts,
                 "table",
                 (value) / (ts - lag(ts) over (partition by "table" order by ts)) as value_per_second
               from
                 data3
               order by 1, 2)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  "table",
  avg(value_per_second)
 from
  data4
 group by 1,2
 order by 1,2
|||,
  row_table_toast_read_bps: |||
 with data as (
  select
    snapshot,
    jsonb_array_elements(value_jsonb) as value_jsonb
  from
    metric
  where
    $__unixEpochFilter(ts)
    and host = md5('$host')::uuid
    and plugin = md5('pg.user_tables.io')::uuid
 )
   , tables as (
  select
    m.value_jsonb ->> 'full_table_name'                             as table,
    sum(coalesce((m.value_jsonb ->> 'toast_blks_read')::float8, 0)) as rows
  from
    data m
  group by 1
  order by 2 desc
  limit 20
 )
   , data2 as (select
                 m.snapshot                                                                 as ts,
                 m.value_jsonb ->> 'full_table_name'                                        as table,
                 sum(coalesce((m.value_jsonb ->> 'toast_blks_read')::float8, 0)) * 8 * 1024 as value
               from
                 data m
                 inner join tables t on t.table = m.value_jsonb ->> 'full_table_name'
               group by 1, 2
               order by 1)
   , data3 as (select
                 ts,
                 "table",
                 sum(value) as value
               from
                 data2
               group by 1, 2
               order by 1, 2)
   , data4 as (select
                 ts,
                 "table",
                 (value) / (ts - lag(ts) over (partition by "table" order by ts)) as value_per_second
               from
                 data3
               order by 1, 2)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  "table",
  avg(value_per_second)
 from
  data4
 group by 1,2
 order by 1,2
|||,
  row_wal_checkpoint_count: |||
 with data as (select
                snapshot                                           as ts,
                sum((value_jsonb ->> 'checkpoints_timed')::bigint) as timed,
                sum((value_jsonb ->> 'checkpoints_req')::bigint)   as required
              from
                metric
              where
                $__unixEpochFilter(ts)
                and host = md5('$host')::uuid
                and plugin = md5('pg.bgwriter')::uuid
              group by 1
              order by 1)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(timed)                                                                as timed,
  avg(required)                                                             as required
 from
  data
 group by 1
 order by 1
|||,
  row_wal_checkpoint_time: |||
 with data as (select
                snapshot                                               as ts,
                sum((value_jsonb ->> 'checkpoint_write_time')::float8) as write,
                sum((value_jsonb ->> 'checkpoint_sync_time')::float8)  as sync
              from
                metric
              where
                $__unixEpochFilter(ts)
                and host = md5('$host')::uuid
                and plugin = md5('pg.bgwriter')::uuid
              group by 1
              order by 1)
  , data2 as (select
                 ts,
                 (write) / (ts - lag(ts) over w) as write,
                 (sync) / (ts - lag(ts) over w)  as sync
               from
                 data
                 window w as (order by ts)
               order by 1)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(write)                                                                as write,
  avg(sync)                                                                 as sync
 from
  data2
 group by 1
 order by 1
|||,
  row_wal_generation: |||
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value_double)                                                         as "wal generation speed"
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('pg.wal.speed')::uuid
 group by 1
 order by 1
|||,
  row_wal_slot: |||
 with data as (select
                ts                    as ts,
                f.key::text           as name,
                f.value::text::bigint as value
              from
                metric m,
                jsonb_each(m.value_jsonb) f
              where
                $__unixEpochFilter(m.ts)
                and m.host = md5('$host')::uuid
                and m.plugin = md5('pg.replication_slots')::uuid
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value),
  name
 from
  data
 group by 1,3
 order by 1,3
|||,
  row_wal_buffers: |||
 with data as (select
                snapshot                                                  as ts,
                (value_jsonb ->> 'buffers_checkpoint')::float8 * 8 * 1024 as checkpoint,
                (value_jsonb ->> 'buffers_clean')::float8 * 8 * 1024      as bgwriter,
                (value_jsonb ->> 'buffers_backend')::float8 * 8 * 1024    as backend
              from
                metric
              where
                $__unixEpochFilter(ts)
                and host = md5('$host')::uuid
                and plugin = md5('pg.bgwriter')::uuid
              order by 1)
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(checkpoint)                                                           as checkpoint,
  avg(bgwriter)                                                             as bgwriter,
  avg(backend)                                                              as backend
 from
  data
 group by 1
 order by 1
|||,
  row_system_cpu: |||
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg((value_jsonb ->> 'user')::float8) / 100                               as user,
  avg((value_jsonb ->> 'nice')::float8) / 100                               as nice,
  avg((value_jsonb ->> 'system')::float8) / 100                             as system,
  avg((value_jsonb ->> 'idle')::float8) / 100                               as idle,
  avg((value_jsonb ->> 'iowait')::float8) / 100                             as iowait,
  avg((value_jsonb ->> 'irq')::float8) / 100                                as irq,
  avg((value_jsonb ->> 'softirq')::float8) / 100                            as softirq,
  avg((value_jsonb ->> 'steal')::float8) / 100                              as steal,
  avg((value_jsonb ->> 'guest')::float8) / 100                              as guest,
  avg((value_jsonb ->> 'guest_nice')::float8)                               as guest_nice
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('linux.cpu')::uuid
 group by 1
 order by 1
|||,
  row_system_cpu_processes_running: |||
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value_bigint)                                                         as "running process"
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('linux.cpu.running')::uuid
 group by 1
 order by 1
|||,
  row_system_cpu_processes_blocked: |||
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value_bigint)                                                         as "blocked process"
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('linux.cpu.blocked')::uuid
 group by 1
 order by 1
|||,
  row_system_cpu_processes_fork_rate: |||
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg(value_double)                                                         as "fork-rate"
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('linux.cpu.fork_rate')::uuid
 group by 1
 order by 1
|||,
  row_system_memory: |||
 select
  time_bucket('"$interval"'::interval, to_timestamp(ts) at time zone 'UTC') as time,
  avg((value_jsonb ->> 'MemFree')::bigint)                                  as memfree,
  avg((value_jsonb ->> 'Buffers')::bigint)                                  as buffers,
  avg((value_jsonb ->> 'Cached')::bigint)                                   as cached,
  avg((value_jsonb ->> 'Dirty')::bigint)                                    as dirty,
  avg((value_jsonb ->> 'Slab')::bigint)                                     as slab
 from
  metric
 where
  $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('linux.memory')::uuid
 group by 1
 order by 1
|||,
  row_system_disk_utilization: |||
 with data as (
  select
    ts                                                        as time,
    value_jsonb ->> 'mountpoint'                              as mountpoint,
    sum(coalesce((value_jsonb ->> 'utilization')::float8, 0)) as value
  from
    metric
  where
    $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('linux.diskstats')::uuid
  group by 1, 2
  order by 1
 )
 select
  time_bucket('"$interval"'::interval, to_timestamp(time) at time zone 'UTC') as time,
  mountpoint,
  avg(value) / 100
 from
  data
 group by 1,2
 order by 1,2
|||,
  row_system_disk_await: |||
 with data as (
  select
    ts                                     as time,
    value_jsonb ->> 'mountpoint'           as mountpoint,
    sum((value_jsonb ->> 'await')::float8) as value
  from
    metric
  where
    $__unixEpochFilter(ts)
  and host = md5('$host')::uuid
  and plugin = md5('linux.diskstats')::uuid
  group by 1, 2
  order by 1)
 select
  time_bucket('"$interval"'::interval, to_timestamp(time) at time zone 'UTC') as time,
  mountpoint,
  avg(value)
 from
  data
 group by 1,2
 order by 1,2
|||,
}
