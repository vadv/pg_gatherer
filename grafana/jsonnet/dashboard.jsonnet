local grafana = import 'vendor/grafonnet-lib/grafonnet/grafana.libsonnet';
local sql = import 'dashboard_sql.libsonnet';

local dashboard = grafana.dashboard.new('PostgreSQL (pg_gatherer)', tags=['postgresql', 'rds'], time_from='now-3h', timezone='UTC')
    .addTemplate(grafana.template.datasource('POSTGRES_DS', 'postgres', 'PostgreSQL', hide='label'))
    .addTemplate(grafana.template.datasource('PROMETHEUS_DS', 'prometheus', 'Prometheus', hide='label'))
    .addTemplate(grafana.template.new('host', '$POSTGRES_DS', 'select name from host order by name;', refresh='load'))
    .addTemplate(grafana.template.custom('interval', '1 minute,10 minute,20 minute,1 hour', '20 minute'));

local statInstanceRow = grafana.row.new( title='Instance stat', collapse=false, height='40px')
    .addPanels([
        grafana.singlestat.new('Uptime', format='s', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, colorBackground=true, thresholds='300, 1800', colors=['#d44a3a','rgba(237, 129, 40, 0.89)', '#299c46'], valueName='min',
        ).addTarget(grafana.sql.target(sql.stat_uptime)),
        grafana.singlestat.new('Size', format='decbytes', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max',
        ).addTarget(grafana.sql.target(sql.stat_size)),
        grafana.singlestat.new('Wal', format='Bps', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max',
        ).addTarget(grafana.sql.target(sql.stat_wal)),
        grafana.singlestat.new('Error/s', format='ops', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='100,500',
        ).addTarget(grafana.sql.target(sql.stat_errors)),
        grafana.singlestat.new('Replication lag', format='s', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='10, 20',
        ).addTarget(grafana.sql.target(sql.stat_repl_lag)),
        grafana.singlestat.new('Slot size', format='decbytes', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='10485760,83886080',
        ).addTarget(grafana.sql.target(sql.stat_repl_slot)),
    ]);
local statQueriesRow = grafana.row.new( title='Queries stat', height='100px', collapse=false)
    .addPanels([
        grafana.singlestat.new('Queries/s', format='ops', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max',
        ).addTarget(grafana.sql.target(sql.stat_qps)),
        grafana.singlestat.new('Avg queries time', format='s', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='3,10',
        ).addTarget(grafana.sql.target(sql.stat_queries_avg)),
        grafana.singlestat.new('Longest query', format='s', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='300,600',
        ).addTarget(grafana.sql.target(sql.stat_long_query)),
        grafana.singlestat.new('Transaction/s', format='ops', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max',
        ).addTarget(grafana.sql.target(sql.stat_tps)),
        grafana.singlestat.new('Idle in tx', format='short', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='100,300',
        ).addTarget(grafana.sql.target(sql.stat_idle_in_tx)),
        grafana.singlestat.new('Waiting queries', format='short', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='40,100',
        ).addTarget(grafana.sql.target(sql.stat_waiting)),
    ]);
local statBufferRow = grafana.row.new( title='Buffers stat', height='100px', collapse=false)
    .addPanels([
        grafana.singlestat.new('Buffer pool (hit ratio)', format='percentunit', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, colorBackground=true, thresholds='0.5,0.8', colors=['#d44a3a','rgba(237, 129, 40, 0.89)', '#299c46'], valueName='min',
        ).addTarget(grafana.sql.target(sql.stat_buff_poll_hit_rate)),
        grafana.singlestat.new('Buffer reuse', format='percentunit', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='0.5,0.8', colors=['#d44a3a','rgba(237, 129, 40, 0.89)', '#299c46'],
        ).addTarget(grafana.sql.target(sql.stat_buffer_reuse)),
        grafana.singlestat.new('Dirty buffers', format='percentunit', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='0.1,0.2',
        ).addTarget(grafana.sql.target(sql.stat_dirty)),
        grafana.singlestat.new('Relation seq scans (>256MB)', format='opm', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='0.8,2',
        ).addTarget(grafana.sql.target(sql.stat_seq_scans)),
        grafana.singlestat.new('Bloat tables', format='percentunit', span=2, decimals=2, datasource='$POSTGRES_DS',
            sparklineShow=true, valueName='max', colorBackground=true, thresholds='0.05,0.2',
        ).addTarget(grafana.sql.target(sql.stat_bloat)),
    ]);

local databasesRow = grafana.row.new(title='Databases', height='300px', collapse=true)
    .addPanels([
        grafana.tablePanel.new('databases', span=12, datasource='$POSTGRES_DS',
        styles=[{pattern: '/.*/', type: 'number', unit: 'short', decimals: 2}],
        ).addTarget(grafana.sql.target(sql.row_databases, format='table')),
    ]);

local tablesRow = grafana.row.new(title='Tables', height='300px', collapse=true)
    .addPanels([
        grafana.tablePanel.new('biggest tables', span=12, datasource='$POSTGRES_DS',
        styles=[
             {pattern: '/size/', type: 'number', unit: 'decbytes', decimals: 2},
             {pattern: '/(deleted|live)/', type: 'number', unit: 'percentunit', decimals: 2},
             {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
        ],
        ).addTarget(grafana.sql.target(sql.row_tables_big, format='table')),
        grafana.tablePanel.new('most changed tables', span=12, datasource='$POSTGRES_DS',
        styles=[
             {pattern: '/size/', type: 'number', unit: 'decbytes', decimals: 2},
             {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
        ],
        ).addTarget(grafana.sql.target(sql.row_tables_change, format='table')),
    ]);

local operationsRow = grafana.row.new(title='Operations', height='400px', collapse=true)
    .addPanels([
        grafana.graphPanel.new(title='Queries/s ($host)',
            datasource='$POSTGRES_DS', linewidth=1, format='ops', stack=true, fill=1, legend_rightSide=true, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_operations_queries)),
        grafana.graphPanel.new(title='Transactions/s ($host)',
            datasource='$POSTGRES_DS', linewidth=1, format='ops', stack=true, fill=1, legend_rightSide=true, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_operations_tx)),
    ]);

local backendsRow = grafana.row.new(title='Backend states', height='400px', collapse=true)
    .addPanels([
        grafana.graphPanel.new(title='Backend states ($host)',
            datasource='$POSTGRES_DS', linewidth=1, format='none', stack=true, fill=1, legend_rightSide=true, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_backend_states)),
        grafana.graphPanel.new(title='Backend states (wait event type $host)',
            datasource='$POSTGRES_DS', linewidth=1, format='none', stack=true, fill=1, legend_rightSide=true, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_backend_wait_event_type)),
        grafana.graphPanel.new(title='Backend states (wait events $host)',
            datasource='$POSTGRES_DS', linewidth=1, format='none', stack=true, fill=1, legend_rightSide=true, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_backend_wait_events)),
    ]);

local statementsStatRow = grafana.row.new(title='Stat statements', height='800px', collapse=true)
    .addPanels([
        grafana.tablePanel.new('Disk read', span=12, datasource='$POSTGRES_DS',
         styles=[
             {pattern: '/disk/', type: 'number', unit: 'decbytes', decimals: 2},
             {pattern: '/time/', type: 'number', unit: 'ms', decimals: 2},
             {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
         ],
        ).addTarget(grafana.sql.target(sql.row_statements_disk_read, format='table')),
        grafana.tablePanel.new('Disk write', span=12, datasource='$POSTGRES_DS',
         styles=[
             {pattern: '/disk/', type: 'number', unit: 'decbytes', decimals: 2},
             {pattern: '/time/', type: 'number', unit: 'ms', decimals: 2},
             {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
         ],
        ).addTarget(grafana.sql.target(sql.row_statements_disk_write, format='table')),
        grafana.tablePanel.new('Execution time', span=12, datasource='$POSTGRES_DS',
        styles=[
            {pattern: '/total_time/', type: 'number', unit: 'ms', decimals: 2},
            {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
        ],
        ).addTarget(grafana.sql.target(sql.row_statements_time, format='table')),
        grafana.tablePanel.new('Temp files', span=12, datasource='$POSTGRES_DS',
         styles=[
             {pattern: '/size/', type: 'number', unit: 'decbytes', decimals: 2},
             {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
         ],
        ).addTarget(grafana.sql.target(sql.row_statements_temp_files, format='table')),
    ]);

local loggedQueriesRow = grafana.row.new(title='Logged statements', height='800px', collapse=true)
    .addPanels([
        grafana.tablePanel.new('Blocks', span=12, datasource='$POSTGRES_DS',
        styles=[
            {pattern: '/seen/', type: 'date', unit: 'Time', dateFormat: "YYYY-MM-DD HH:mm:ss"},
            {pattern: '/duration/', type: 'number', unit: 's', decimals: 2},
            {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
        ],
        ).addTarget(grafana.sql.target(sql.row_logged_statements_lock, format='table')),
        grafana.tablePanel.new('Long queries', span=12, datasource='$POSTGRES_DS',
        styles=[
            {pattern: '/seen/', type: 'date', unit: 'Time', dateFormat: "YYYY-MM-DD HH:mm:ss"},
            {pattern: '/duration/', type: 'number', unit: 's', decimals: 2},
            {pattern: '/(read|write)/', type: 'number', unit: 'decbytes', decimals: 2},
            {pattern: '/(user|system)/', type: 'number', unit: 's', decimals: 2},
            {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
        ],
        ).addTarget(grafana.sql.target(sql.row_logged_statements_long, format='table')),
        grafana.tablePanel.new('Autovacuum', span=6, datasource='$POSTGRES_DS',
        styles=[
            {pattern: '/last_/', type: 'date', unit: 'Time', dateFormat: "YYYY-MM-DD HH:mm:ss"},
            {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
        ],
        ).addTarget(grafana.sql.target(sql.row_logged_statements_autovacuum, format='table')),
        grafana.tablePanel.new('Autoanalyze', span=6, datasource='$POSTGRES_DS',
        styles=[
            {pattern: '/last_/', type: 'date', unit: 'Time', dateFormat: "YYYY-MM-DD HH:mm:ss"},
            {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
        ],
        ).addTarget(grafana.sql.target(sql.row_logged_statements_autoanalyze, format='table')),
    ]);

local seqScanRow = grafana.row.new(title='Seq scans', height='400px', collapse=true)
    .addPanels([
        grafana.tablePanel.new('Sequential scans tables > 256Mb', span=12, datasource='$POSTGRES_DS',
        styles=[
            {pattern: '/timestamp/', type: 'date', unit: 'Time', dateFormat: "YYYY-MM-DD HH:mm:ss"},
            {pattern: '/count/', type: 'number', unit: 'none'},
            {pattern: '/table size/', type: 'number', unit: 'decbytes', decimals: 2},
            {pattern: '/.*/', type: 'number', unit: 'short', decimals: 2},
        ],
        ).addTarget(grafana.sql.target(sql.row_seq_scan, format='table')),
    ]);

local bufferPoolRow = grafana.row.new(title='Buffer pool usage', height='400px', collapse=true)
    .addPanels([
        grafana.graphPanel.new(title='Buffer pool per relation ($host)',
            datasource='$POSTGRES_DS', linewidth=1, format='decbytes', stack=true, fill=1, legend_rightSide=true, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_buffer_pool_relation)),
        grafana.graphPanel.new(title='Buffer pool dirty',
            datasource='$POSTGRES_DS', linewidth=1, format='decbytes', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='300px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_buffer_pool_dirty)),
        grafana.graphPanel.new(title='Buffer pool (usagecount == 0)',
            datasource='$POSTGRES_DS', linewidth=1, format='decbytes', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='300px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_buffer_pool_usagecount_0)),
        grafana.graphPanel.new(title='Buffer pool (usagecount >= 3)',
            datasource='$POSTGRES_DS', linewidth=1, format='decbytes', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='300px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_buffer_pool_usagecount_3)),
        grafana.graphPanel.new(title='Buffer per database',
            datasource='$POSTGRES_DS', linewidth=1, format='decbytes', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='300px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_buffer_pool_database)),
    ]);

local tableRow = grafana.row.new(title='Table read/modify (tuples/disk)', height='600px', collapse=true)
    .addPanels([
        grafana.graphPanel.new(title='Seq scan tuples access',
            datasource='$POSTGRES_DS', linewidth=1, format='ops', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='600px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_table_seq_scan)),
        grafana.graphPanel.new(title='Index tuples access',
            datasource='$POSTGRES_DS', linewidth=1, format='ops', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='600px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_table_index)),
        grafana.graphPanel.new(title='Changed tuples',
            datasource='$POSTGRES_DS', linewidth=1, format='ops', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='600px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_table_changed)),
        grafana.graphPanel.new(title='Heap (read from disk)',
            datasource='$POSTGRES_DS', linewidth=1, format='Bps', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='600px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_table_heap_read_bps)),
        grafana.graphPanel.new(title='Index (read from disk)',
            datasource='$POSTGRES_DS', linewidth=1, format='Bps', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='600px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_table_index_read_bps)),
        grafana.graphPanel.new(title='Toast (read from disk)',
            datasource='$POSTGRES_DS', linewidth=1, format='Bps', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=4, height='600px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_table_toast_read_bps)),
    ]);

local walRow = grafana.row.new(title='WAL', height='600px', collapse=true)
    .addPanels([
        grafana.graphPanel.new(title='Checkponts (count)',
            datasource='$POSTGRES_DS', linewidth=1, format='ops', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_wal_checkpoint_count)),
        grafana.graphPanel.new(title='Checkponts (time/per second)',
            datasource='$POSTGRES_DS', linewidth=1, format='ms', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_wal_checkpoint_time)),
        grafana.graphPanel.new(title='WAL speed',
            datasource='$POSTGRES_DS', linewidth=1, format='Bps', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true, legend_rightSide=false,
        ).addTarget(grafana.sql.target(sql.row_wal_generation)),
        grafana.graphPanel.new(title='Slot sizes',
            datasource='$POSTGRES_DS', linewidth=1, format='decbytes', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true, legend_rightSide=false,
        ).addTarget(grafana.sql.target(sql.row_wal_slot)),
        grafana.graphPanel.new(title='Buffers write',
            datasource='$POSTGRES_DS', linewidth=1, format='Bps', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true, legend_rightSide=false,
        ).addTarget(grafana.sql.target(sql.row_wal_buffers)),
    ]);

local systemRow = grafana.row.new(title='System', height='600px', collapse=true)
    .addPanels([
        grafana.graphPanel.new(title='CPU',
            datasource='$POSTGRES_DS', linewidth=1, format='percentunit', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_system_cpu)),
        grafana.graphPanel.new(title='CPU: running/blocked && fork-rate',
            datasource='$POSTGRES_DS', linewidth=1, format='short', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTargets([
            grafana.sql.target(sql.row_system_cpu_processes_running),
            grafana.sql.target(sql.row_system_cpu_processes_blocked),
            //grafana.sql.target(sql.row_system_cpu_processes_fork_rate),
          ]),
        grafana.graphPanel.new(title='Memory',
            datasource='$POSTGRES_DS', linewidth=1, format='decbytes', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_system_memory)),
        grafana.graphPanel.new(title='Disk utilization',
            datasource='$POSTGRES_DS', linewidth=1, format='percentunit', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_system_disk_utilization)),
        grafana.graphPanel.new(title='Disk await',
            datasource='$POSTGRES_DS', linewidth=1, format='ms', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            bars=true, lines=false, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
        ).addTarget(grafana.sql.target(sql.row_system_disk_await)),
    ]);

local rdsRow = grafana.row.new(title='RDS metrics', height='600px', collapse=true)
    .addPanels([
        grafana.graphPanel.new(title='Memory',
            datasource='$PROMETHEUS_DS', linewidth=1, format='decbytes', stack=false, fill=1, legend_sort='max', legend_sortDesc=true,
            lines=true, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
            ).addTargets([
                grafana.prometheus.target(
                    'avg_over_time(aws_rds_freeable_memory_average{dbinstance_identifier="$host"}[$__interval])',
                        legendFormat='Freeable'),
                grafana.prometheus.target(
                    'avg_over_time(aws_rds_memory_total{dbinstance_identifier="$host"}[$__interval])',
                        legendFormat='Total'),
            ]),
        grafana.graphPanel.new(title='CPU',
            datasource='$PROMETHEUS_DS', linewidth=1, format='percentunit', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            lines=true, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
            ).addTarget(
                grafana.prometheus.target(
                    'avg_over_time(aws_rds_cpuutilization_average{dbinstance_identifier="$host"}[$__interval]) / 100',
                        legendFormat='CPU'),
            ),
        grafana.graphPanel.new(title='IOPS',
            datasource='$PROMETHEUS_DS', linewidth=1, format='ops', stack=true, fill=1, legend_sort='max', legend_sortDesc=true,
            lines=true, transparent=true, min=0, legend_alignAsTable=true, span=12, height='400px', legend_rightSide=true,
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
            ).addTargets([
                grafana.prometheus.target(
                    'avg_over_time(aws_rds_write_iops_average{dbinstance_identifier="$host"}[$__interval])',
                        legendFormat='Write ops'),
                grafana.prometheus.target(
                    'avg_over_time(aws_rds_read_iops_average{dbinstance_identifier="$host"}[$__interval])',
                        legendFormat='Read ops'),
            ]),
    ]);

local pluginRow = grafana.row.new(title='Common metrics of plugins', height='600px', collapse=true)
    .addPanels([
        grafana.graphPanel.new(title='Errors by plugin',
            datasource='$PROMETHEUS_DS', linewidth=1, format='ops', stack=false, fill=1, legend_sort='max', legend_sortDesc=true,
            lines=true, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
            ).addTargets([
                grafana.prometheus.target(
                    'sum(rate(pg_gatherer_plugin_errors{}[$__interval])) by (plugin)',
                        legendFormat='{{plugin}}')
            ]),
        grafana.graphPanel.new(title='Errors by host',
            datasource='$PROMETHEUS_DS', linewidth=1, format='ops', stack=false, fill=1, legend_sort='max', legend_sortDesc=true,
            lines=true, transparent=true, min=0, legend_alignAsTable=true, span=6, height='400px',
            legend_show=true, legend_values=true, legend_min=true, legend_max=true, legend_avg=true,
            ).addTargets([
                grafana.prometheus.target(
                    'sum(rate(pg_gatherer_plugin_errors{}[$__interval])) by (host)',
                        legendFormat='{{host}}')
            ]),
    ]);

dashboard.addRow(statInstanceRow).addRow(statQueriesRow).addRow(statBufferRow)
    .addRow(databasesRow).addRow(tablesRow).addRow(operationsRow).addRow(backendsRow).addRow(statementsStatRow)
    .addRow(loggedQueriesRow).addRow(seqScanRow).addRow(bufferPoolRow).addRow(tableRow)
    .addRow(walRow).addRow(systemRow).addRow(rdsRow).addRow(pluginRow)
