Creates lua user data `connection_ud`.

# Golang

```go
	state := lua.NewState()
	connection.Preload(state)
	// register user data "test"
	connection.New(state, "test", "/tmp", "coinsph-db-test", 5432, "coinsph-user-test", "coinsph-password")
	// register user data "connection"
	connection.New(state, "connection", "/tmp", "coinsph-db", 5432, "coinsph-user", "coinsph-password")
```

# Lua

## connection:query(string, args...)

Execute read-only query with args. Return table with `rows` and `columns` and error.

```lua
local result, err = connection:query("select $1::integer, $1::text, $2", 1, "tests")
--[[
result:
  {
    columns = { "int4", "text", "?column?" },
    rows = { { 1, "1", "1" } }
  }
--]]
```

## connection:available_connections()

List of available connections in this PostgreSQL instance. Return list of user data `connection_ud` and error.

```lua
local connections, err = connection:available_connections()
if err then error(err) end
connections[1]:query("select 1")
```