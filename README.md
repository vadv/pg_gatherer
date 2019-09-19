# pg_gatherer

The project is designed to collect and store statistical data of PostgreSQL into other PostgreSQL.

# Architecture

```
              +------------------+
       +------+     Grafana      |
       |      +------------------+
       v
+------+-------+                        +---------------+
|   Manager    |     +----------------->+   Target #1   |
+------+-------+     |                  +---------------+
       ^             |
       |     +-------+--------+         +---------------+
       +-----+     Agent      +-------->+   Target #N   |
             +----------------+         +---------------+
```

## Targets

Targets databases, which agent monitoring.

## Manager

PostgreSQL database (with [TimescaleDB](https://docs.timescale.com/latest/introduction) extension) in which information is stored.

## Agent

The agent is golang-binary, with plugins written in Lua (without any system dependencies).

You can run agent locally on machine `Target`, then you get additional statistics (link /proc/{pid}/io) info with query.

## Installation

* Install manager database.
* Apply [migration](/schema/schema.sql) on manager database.
* Get [plugins](/plugins).
* Get agent:

```bash
go get github.com/vadv/pg_gatherer/gatherer/cmd/pg_gatherer
pg_gatherer --config config.yaml
```

Config example:

```yaml
plugins_dir: ./plugins # path to plugins
cache_dir: /tmp/gatherer # plugins cache

hosts:

  - host: peripheral-db-1 # name of target in manager-db

    plugins:
      - activity # list of plugins

    manager: # manager (TimescaleDB) connection
      host: /tmp
      dbname: gatherer
      username: gatherer
      port: 5432

    agent: # target connection
      host: /tmp
      dbname: gatherer
      username: gatherer
      port: 5432
```

# Build status

[![Travis](https://travis-ci.org/vadv/pg_gatherer.svg)](https://travis-ci.org/vadv/pg_gatherer)