Creates lua user data `cache_ud`.

# Golang

```go
	state := lua.NewState()
	cache.Preload(state)
	// register user data "cache"
	cache.NewSqlite(state, "cache", "/tmp/db.sqlite")
```

# Lua

## cache:set(string, number)

Set `number` to cache by key `string`, raise error.

## cache:get(string)

Get `number` from cache by key `string`. Return `number` or `nil`, raise error.

## cache:diff_and_set(string, value)

Get `number`, diff from previous value. Return `number` or `nil`, raise error.

## cache:speed_and_set(string, value)

Get `number`, speed based on previous value. Return `number` or nil, raise error.