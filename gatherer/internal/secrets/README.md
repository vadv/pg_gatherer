Creates lua user data `secret_ud`.

# Golang

```go
	state := lua.NewState()
	secrets.Preload(state)
	s := secrets.New(filename)
	// register user data "secrets"
	s.Register(state, "secrets")
```

# Lua

## secret:get(key)

Get secret, return string or nil.