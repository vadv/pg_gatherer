Creates lua user data `manager_ud`.

# Golang

```go
	state := lua.NewState()
	manager.Preload(state)
	// register user data "manager"
	manager.New(state, "manager", "host=/tmp dbname=")
```

# Lua

## manager:metric({host="", plugin="", [int=0,float=0,json=""]})

Save metric to manager database.

# SQL

```sql
create table metric (
    id           bigserial,
    host         uuid not null,
    plugin       uuid not null,
    ts           bigint not null default extract(epoch from current_timestamp)::bigint,
    snapshot     bigint,
    value_bigint bigint,
    value_double float8,
    value_jsonb  jsonb
);
-- select create_hypertable('metric', 'ts', chunk_time_interval => 43200);
create index ON metric (ts, plugin, host);
```