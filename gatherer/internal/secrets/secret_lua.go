package secrets

import (
	lua "github.com/yuin/gopher-lua"
)

// Preload is the preloader of user data secret_ud.
func Preload(L *lua.LState) int {
	secretUD := L.NewTypeMetatable(`secret_ud`)
	L.SetGlobal(`secret_ud`, secretUD)
	L.SetField(secretUD, "__index", L.SetFuncs(L.NewTable(), map[string]lua.LGFunction{
		"get": getSecret,
	}))
	return 0
}

// Register secrets_ud in state
func (s *Storage) Register(L *lua.LState, userDataName string) {
	ud := L.NewUserData()
	ud.Value = s
	L.SetMetatable(ud, L.GetTypeMetatable(`secret_ud`))
	L.SetGlobal(userDataName, ud)
}

func checkSecret(L *lua.LState, n int) *Storage {
	ud := L.CheckUserData(n)
	if v, ok := ud.Value.(*Storage); ok {
		return v
	}
	L.ArgError(n, "secret_ud expected")
	return nil
}

// return plugin dir
func getSecret(L *lua.LState) int {
	s := checkSecret(L, 1)
	key := L.CheckString(2)
	secret := s.get(key)
	if secret != nil {
		result := *secret
		L.Push(lua.LString(result))
		return 1
	}
	return 0
}
