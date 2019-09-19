package cache

import (
	"time"

	lua "github.com/yuin/gopher-lua"
)

// checkUserDataCache return connection from lua state
func checkUserDataCache(L *lua.LState, n int) *cacheUserData {
	ud := L.CheckUserData(n)
	if v, ok := ud.Value.(*cacheUserData); ok {
		return v
	}
	L.ArgError(n, "cache_ud expected")
	return nil
}

// set key with value
func set(L *lua.LState) int {
	ud := checkUserDataCache(L, 1)
	key := L.CheckString(2)
	value := L.CheckNumber(3)
	if err := ud.Set(key, float64(value)); err != nil {
		L.RaiseError("cache error: %s", err.Error())
	}
	return 0
}

// get key
func get(L *lua.LState) int {
	ud := checkUserDataCache(L, 1)
	key := L.CheckString(2)
	value, updatedAt, found, err := ud.Get(key)
	if err != nil {
		L.RaiseError("cache error: %s", err.Error())
		return 0
	}
	if !found {
		L.Push(lua.LNil)
		L.Push(lua.LNil)
		return 2
	}
	L.Push(lua.LNumber(value))
	L.Push(lua.LNumber(updatedAt))
	return 2
}

// diff key
func diffAndSet(L *lua.LState) int {
	ud := checkUserDataCache(L, 1)
	key := L.CheckString(2)
	currentValue := L.CheckNumber(3)
	prevValue, _, found, err := ud.Get(key)
	if err != nil {
		L.RaiseError("cache error: %s", err.Error())
		return 0
	}
	if err := ud.Set(key, float64(currentValue)); err != nil {
		L.RaiseError("cache error: %s", err.Error())
		return 0
	}
	if !found {
		// not found, return nil
		L.Push(lua.LNil)
		return 1
	}
	// found, calc diff
	result := float64(currentValue) - prevValue
	L.Push(lua.LNumber(result))
	return 1
}

func speedAndSet(L *lua.LState) int {
	ud := checkUserDataCache(L, 1)
	key := L.CheckString(2)
	currentValue := L.CheckNumber(3)
	prevValue, updatedAt, found, err := ud.Get(key)
	if err != nil {
		L.RaiseError("cache error: %s", err.Error())
		return 0
	}
	if err := ud.Set(key, float64(currentValue)); err != nil {
		L.RaiseError("cache error: %s", err.Error())
		return 0
	}
	if !found {
		// not found, return nil
		L.Push(lua.LNil)
		return 1
	}
	// found, calc diff
	result := (float64(currentValue) - prevValue) / float64(time.Now().Unix()-updatedAt)
	L.Push(lua.LNumber(result))
	return 1
}
