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

$ AGENT_PRIV_CONNECTION="host=target user=postgres" glua-libs ./schema/agent/deploy.lua
```

# Seed

```sql
insert into manager.host (token, agent_token, databases, maintenance, severity_policy_id)
    values ( 'hostname', 'token-key', '{"dbname"}'::text[], false, null);
```

# Start Agent

```
$ go get github.com/vadv/gopher-lua-libs/cmd/glua-libs
$ TOKEN=xxx CONNECTION_AGENT=xxx CONNECTION_MANAGER=xxx glua-libs ./agent/init.lua
```

# Start AlertManager

```
$ CONNECTION_MANAGER=xxx PAGERDUTY_TOKEN=xxx PAGERDUTY_RK_DEFAULT=xxx glua-libs ./alertmanager/init.lua
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
        $__unixEpochFilter(ts) AND
        host = md5('$host')::uuid AND
        plugin = md5('pg.user_tables.io')::uuid
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 20
)

SELECT
  m.ts AS "time",
  m.value_jsonb->>'full_table_name' as "table",
  sum( coalesce((m.value_jsonb->>'heap_blks_read')::float8, 0) )  * 8 * 1024 as "heap"
FROM manager.metric m
INNER JOIN top_20_tables t ON t.table = m.value_jsonb->>'full_table_name'
WHERE
  $__unixEpochFilter(ts) AND
  host = md5('$host')::uuid AND
  plugin = md5('pg.user_tables.io')::uuid
GROUP BY 1,2
ORDER BY 1
```

or use the sql language to find problem :)

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
