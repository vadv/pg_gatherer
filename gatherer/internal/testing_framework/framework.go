package testing_framework

import (
	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"
	lua "github.com/yuin/gopher-lua"
)

type framework struct {
	pool       *plugins.Pool
	pluginName string
	host       string
}

// Preload is the preloader of user data connection_ud.
func Preload(L *lua.LState) int {
	frameworkUD := L.NewTypeMetatable(`testing_framework_ud`)
	L.SetGlobal(`testing_framework_ud`, frameworkUD)
	L.SetField(frameworkUD, "__index", L.SetFuncs(L.NewTable(), map[string]lua.LGFunction{
		"create":        createPlugin,
		"remove":        removePlugin,
		"restart_count": restartCount,
		"error_count":   errorCount,
		"last_error":    lastError,
	}))
	return 0
}

// New create new testing_framework into lua state as user data
func New(L *lua.LState, rootDir, cacheDir, pluginName, host, dbname, user, password string, port int, params map[string]string) error {
	pool := plugins.NewPool(rootDir, cacheDir)
	conn := &plugins.Connection{
		Host:     host,
		DBName:   dbname,
		Port:     port,
		UserName: user,
		Password: password,
		Params:   params,
	}
	connections := make(map[string]*plugins.Connection)
	connections[`target`] = conn
	connections[`storage`] = conn
	f := &framework{
		pool:       pool,
		pluginName: pluginName,
		host:       pluginName,
	}
	pool.RegisterHost(f.host, connections)
	ud := L.NewUserData()
	ud.Value = f
	L.SetMetatable(ud, L.GetTypeMetatable(`testing_framework_ud`))
	L.SetGlobal("plugin", ud)
	return nil
}
