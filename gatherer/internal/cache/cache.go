package cache

import (
	"github.com/vadv/pg_gatherer/gatherer/internal/cache/sqlite"
	lua "github.com/yuin/gopher-lua"
)

type cache interface {
	Set(key string, value float64) error
	Get(key string) (float64, int64, bool, error)
	Delete(key string) error
}

type cacheUserData struct {
	cache
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

func NewSqlite(L *lua.LState, userDataName, fileName string) error {
	s, err := sqlite.New(fileName)
	if err != nil {
		return err
	}
	c := &cacheUserData{s}
	ud := L.NewUserData()
	ud.Value = c
	L.SetMetatable(ud, L.GetTypeMetatable(`cache_ud`))
	L.SetGlobal(userDataName, ud)
	return nil
}
