# Internal API

## Structures

### Connection

```lua
_ = {
    host     = 'hostname',
    dbname   = 'dbname',
    user     = 'user',
    port     = 5432,
    password = 'password'
}
```

### Metric

```lua
_ = {
    host   = 'hostname',
    plugin = 'plugin',
    ts     = 1500000,
-- metric value
    int    = 0,
    -- or float = 0.0,
    -- or json = '{}'
}
```

### DBResult

```lua
_ = {
    rows =    {}, --{ {0,nil,""}, {nil,1,nil} },
    columns = {}, --{"col1", "col2", "col3"},
}
```

## Helpers

* `helpers.get_connection()` return `Connection`
* `helpers.get_available_connections()` return `{Connection, ...}`
* `helpers.query(Connection)` return `DBResult, err`
* `helpers.diff(string, numeric)` return `numeric, err`
* `helpers.speed(string, numeric)` return `numeric, err`
* `helpers.send_metric(Metric)` return `err`