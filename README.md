# pg_gatherer

project is designed to collect and store statistical data of postgresql into other postgresql.

# Architecture

* target: target database
* manager: database in which information is stored

![Architecture](/img/arch.png)

# Agent

Agent is golang-binary with plugins written in lua ( [vadv/gopher-lua-libs](https://github.com/vadv/gopher-lua-libs) ).

# AlertManager

AlertManager is also lua-pluginable. Currently supports telegram and PagerDuty only.

# Deploy

on manager database:

```
$ psql -h manager -d manager -U postgres -1 -f ./schema/manager/schema.sql
$ psql -h manager -d manager -U postgres -1 -f ./schema/manager/functions.sql
```

on target database:

```
$ psql -h target -d target -U postgres -1 -f ./schema/agent/init.sql
$ psql -h target -d target -U postgres -1 -f ./schema/agent/plugin*_.sql

or

$ AGENT_PRIV="host=target user=postgres" glua-libs ./schema/agent/deploy.lua
```

# Seed

```sql
insert into manager.host (token, agent_token, main_connection, additional_connections, maintenance, severity_policy_id)
    values ( 'hostname', 'token-key', 'host=xxx dbname=xxx', '{"host=xxx dbname=yyy"}'::text[], false, null);
```

# Start Agent

```
$ go get --tags 'sqlite' github.com/vadv/gopher-lua-libs/cmd/glua-libs
$ TOKEN=xxx MANAGER="host=xxx" glua-libs ./agent/init.lua
```

# Start AlertManager

```
$ go get --tags 'sqlite' github.com/vadv/gopher-lua-libs/cmd/glua-libs
$ MANAGER="host=xxx" PAGERDUTY_TOKEN=xxx PAGERDUTY_RK_DEFAULT=xxx glua-libs ./alertmanager/init.lua
```

# Metrics

You can easily to add new metrics to dashboard grafana using sql:

```sql
WITH top_20_tables AS(
    SELECT
        m.value_jsonb->>'full_table_name' as "table",
        sum( coalesce((m.value_jsonb->>'heap_blks_read')::float8, 0) )  as "rows"
    FROM manager.metric m
    WHERE
        $__unixEpochFilter(snapshot) AND
        host = md5('$host')::uuid AND
        plugin = md5('pg.user_tables.io')::uuid
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 20
)

SELECT
  m.snapshot AS "time",
  m.value_jsonb->>'full_table_name' as "table",
  sum( coalesce((m.value_jsonb->>'heap_blks_read')::float8, 0) )  * 8 * 1024 as "heap"
FROM manager.metric m
INNER JOIN top_20_tables t ON t.table = m.value_jsonb->>'full_table_name'
WHERE
  $__unixEpochFilter(snapshot) AND
  host = md5('$host')::uuid AND
  plugin = md5('pg.user_tables.io')::uuid
GROUP BY 1,2
ORDER BY 1
```

or use the sql language to find problem :)

```sql
SELECT
  snapshot as "time",
  sum( coalesce((value_jsonb->>'seq_scan')::float8, 0) )
from manager.metric where
  ts > 1500000000 AND
  host = md5('hostname')::uuid AND
  plugin = md5('pg.user_tables')::uuid AND
  coalesce((value_jsonb->>'relpages')::bigint, 0)> (256*1024*1024) / (8*1024)
group by snapshot
order by snapshot;
```

![common](/img/common-stats.png)
![databases](/img/databases.png)
![backends status](/img/backends-status.png)
![backends waits](/img/backends-waits.png)
![statements](/img/statements.png)
![locks](/img/locks.png)
![long queries](/img/long-queries.png)
![read per table](/img/read-per-table.png)
![tuples per table](/img/tuples-per-table.png)
![seq scans per table](/img/seq-scans-per-table.png)
![cpu](/img/cpu.png)
![disk](/img/disk.png)
![memory](/img/memory.png)
![vacuum-activity](/img/vacuum-activity.png)
![buffers-write](/img/buffers-write.png)
