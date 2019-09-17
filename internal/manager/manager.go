package manager

import (
	"database/sql"
	"sync"

	lua "github.com/yuin/gopher-lua"
)

var listOfOpenedManagerConnections = &listOfManagerConnections{
	mutex: sync.Mutex{},
	list:  make(map[string]*sql.DB),
}

type listOfManagerConnections struct {
	mutex sync.Mutex
	list  map[string]*sql.DB
}

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
	listOfOpenedManagerConnections.mutex.Lock()
	defer listOfOpenedManagerConnections.mutex.Unlock()
	db, ok := listOfOpenedManagerConnections.list[connection]
	if !ok {
		newDB, err := sql.Open(`postgres`, connection)
		if err != nil {
			return err
		}
		newDB.SetMaxOpenConns(1)
		newDB.SetMaxIdleConns(1)
		listOfOpenedManagerConnections.list[connection] = newDB
		db = newDB
	}
	m := &manager{db: db, host: host}
	ud := L.NewUserData()
	ud.Value = m
	L.SetMetatable(ud, L.GetTypeMetatable(`manager_ud`))
	L.SetGlobal(userDataName, ud)
	return nil
}
