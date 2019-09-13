package cache

import (
	"github.com/coins.ph/pg_gatherer/cache/sqlite"
	lua "github.com/yuin/gopher-lua"
)

type Cache interface {
	Set(key string, value float64) error
	Get(key string) (float64, int64, bool, error)
}

type cacheUserData struct {
	Cache
}

// Preload is the preloader of user data connection_ud.
func Preload(L *lua.LState) int {
	connectionUd := L.NewTypeMetatable(`cache_ud`)
	L.SetGlobal(`cache_ud`, connectionUd)
	L.SetField(connectionUd, "__index", L.SetFuncs(L.NewTable(), map[string]lua.LGFunction{
		"set":           set,
		"get":           get,
		"diff_and_set":  diffAndSet,
		"speed_and_set": speedAndSet,
	}))
	return 0
}

func NewSqlite(L *lua.LState, userDataName, path string) error {
	sqlite, err := sqlite.New(path)
	if err != nil {
		return err
	}
	cache := &cacheUserData{sqlite}
	ud := L.NewUserData()
	ud.Value = cache
	L.SetMetatable(ud, L.GetTypeMetatable(`cache_ud`))
	L.SetGlobal(userDataName, ud)
	return nil
}
