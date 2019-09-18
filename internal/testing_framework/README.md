Way to test plugin.

# Golang

```go
	state := lua.NewState()
	testing_framework.Preload(state)
	testing_framework.New(state, "./root_of_plugins/", "plugin_name",
		"host", "gatherer-db-test", 5432, "gatherer-user-test", "gatherer-password")
```

# Lua

## plugin:create()

Start "plugin.lua" in background, raise error if plugin already created.

## plugin:remove()

Stop "plugin.lua" (raise error 'context canceled' in plugin), raise error if plugin was removed.

## plugin:restart_count()

Get restart count of plugin, raise error if plugin was removed.

## plugin:error_count()

Get restart with error count of plugin, raise error if plugin was removed.

## plugin:last_error()

Get string with error text, raise error if plugin was removed.

## connection:query()

Execute read-only query in manager-db with args. Return table with `rows` and `columns`, raise error.

```lua
local result = manager_connection:query("select $1::integer, $1::text, $2", 1, "tests")
--[[
result:
  {
    columns = { "int4", "text", "?column?" },
    rows = { { 1, "1", "1" } }
  }
--]]
```