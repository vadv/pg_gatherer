# pg_gatherer

The project is designed to collect and store statistical data of PostgreSQL into other PostgreSQL.

# Architecture

```
           +------------+               +---------------+
       +---+   Grafana  |          +--->+  Target # 1   |
       |   +------------+          |    +---------------+
       v                           |
+------+-------+                   |    +---------------+
|   Storage    |     +-------------+--->+  Target # N   |
+------+-------+     |                  +---------------+
       ^             |
       |     +-------+--------+         +---------------+
       +-----+   pg_gatherer  +<--------+  Prometheus   |
             +---------+------+         +---------------+
                       |
+----------------+     |         +-----------------------+
|Pager Dutty Api +<----+-------> | Other api (zabbix, ..)|
+----------------+               +-----------------------+
```

## Targets

Targets databases, which agent monitoring.

## Storage

PostgreSQL database (recommended use [TimescaleDB](https://docs.timescale.com/latest/introduction) extension) in which information is stored.

## Pg_Gatherer

The agent is golang-binary, with plugins written in Lua (without any system dependencies).

You can run agent locally on machine `Target`,
then you get additional statistics, for example link `/proc/{pid}/io` stats with query.

## Installation

* Install storage database.
* Apply [migration](/schema/schema.sql) on storage database.
* Create user on targets with [pg_monitor](https://www.postgresql.org/docs/10/default-roles.html) rights.
* Get && run agent.
* Populate table host on storage database.
* Also, if you use TimescaleDB, when you can use Grafana [dashboard](/grafana).

```bash
go get github.com/vadv/pg_gatherer/gatherer/cmd/pg_gatherer
pg_gatherer --host-config-file host-config.yaml --plugins-dir /etc/pg_gatherer/plugins --cache-dir /var/cache --http-listen 8080
```

Host config example:

```yaml
peripheral-db-1: # name of target in storage-db

  plugins: # list of plugins which can be activated on this target
    - activity
    - databases
    ...

  connections:
    target: # target agent connection
      host: 192.168.1.1
      dbname: your_database
      username: monitor
      port: 5432
    storage: # storage connection
      host: /tmp
      dbname: gatherer
      username: storage
      port: 5432
```

# Build status

[![Travis](https://travis-ci.org/vadv/pg_gatherer.svg)](https://travis-ci.org/vadv/pg_gatherer)
