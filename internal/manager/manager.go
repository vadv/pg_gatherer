package manager

import (
	"database/sql"

	lua "github.com/yuin/gopher-lua"
)

// manager connection to PostgreSQL
type manager struct {
	db   *sql.DB
	host string
}

// Preload is the preloader of user data connection_ud.
func Preload(L *lua.LState) int {
	managerUd := L.NewTypeMetatable(`manager_ud`)
	L.SetGlobal(`manager_ud`, managerUd)
	L.SetField(managerUd, "__index", L.SetFuncs(L.NewTable(), map[string]lua.LGFunction{
		"set_metric":  setMetric,
		"send_metric": setMetric,
		"metric":      setMetric,
	}))
	return 0
}

// New create new manager into lua state as user data
func New(L *lua.LState, userDataName, host, connection string) error {
	db, err := sql.Open(`postgres`, connection)
	if err != nil {
		return err
	}
	db.SetMaxOpenConns(1)
	db.SetMaxIdleConns(1)
	m := &manager{db: db, host: host}
	ud := L.NewUserData()
	ud.Value = m
	L.SetMetatable(ud, L.GetTypeMetatable(`manager_ud`))
	L.SetGlobal(userDataName, ud)
	return nil
}
