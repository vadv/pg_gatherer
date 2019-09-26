Creates lua user data `connection_ud`.

# Golang

```go
	state := lua.NewState()
	connection.Preload(state)
	connection.SetMaxOpenConns(1)
	// register user data "test"
	connection.New(state, "test", "/tmp", "gatherer-db-test", 5432, "gatherer-user-test", "gatherer-password", params map[string]string)
	// register user data "new"
	connection.New(state, "new", "/tmp", "gatherer-db", 5432, "gatherer-user", "gatherer-password", params map[string]string)
```

# Lua

## connection:query(string, args...)

Execute read-only query with args. Return table with `rows` and `columns`, raise error.

```lua
local result = connection:query("select $1::integer, $1::text, $2", 1, "tests")
--[[
result:
  {
    columns = { "int4", "text", "?column?" },
    rows = { { 1, "1", "1" } }
  }
--]]
```

## connection:available_connections()

List of available connections in this PostgreSQL instance. Return list of user data `connection_ud`, raise error.

```lua
local connections, err = connection:available_connections()
if err then error(err) end
connections[1]:query("select 1")
```

## connection:insert_metric({plugin="", [int=0,float=0,json=""]})

Save metric to database, raises error.

## connection:background_query(string, args...)

Execute query with args in background, return user data `background_query_ud`.

## background_query_ud:cancel()

Cancel background query.

## background_query_ud:is_running()

Return true if query is already running.

## background_query_ud:result()

Return `result` table like `connection:query()`, raise error if error was canceled on not executed.