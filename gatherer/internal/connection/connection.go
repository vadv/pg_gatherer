package connection

import (
	"database/sql"
	"fmt"
	"sort"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

// connection to PostgreSQL
type connection struct {
	db             *sql.DB
	host           string
	dbname         string
	port           int
	user           string
	password       string
	maxConnections int64
	params         map[string]string
}

// Preload is the preloader of user data connection_ud.
func Preload(L *lua.LState) int {
	connectionUd := L.NewTypeMetatable(`connection_ud`)
	L.SetGlobal(`connection_ud`, connectionUd)
	L.SetField(connectionUd, "__index", L.SetFuncs(L.NewTable(), map[string]lua.LGFunction{
		"query":                 query,
		"available_connections": availableConnections,
		"background_query":      runBackgroundQuery,
		"insert_metric":         insertMetric,
	}))
	backgroundQueryUd := L.NewTypeMetatable(`background_query_ud`)
	L.SetGlobal(`background_query_ud`, backgroundQueryUd)
	L.SetField(backgroundQueryUd, "__index", L.SetFuncs(L.NewTable(), map[string]lua.LGFunction{
		"is_running": backgroundQueryIsRunning,
		"result":     backgroundQueryResult,
		"cancel":     backgroundQueryCancel,
	}))
	return 0
}

// New create new connection into lua state as user data
func New(L *lua.LState, userDataName, host, dbname, user, password string, port int, params map[string]string) {
	c := &connection{
		host:     host,
		dbname:   dbname,
		port:     port,
		user:     user,
		password: password,
		params:   params,
	}
	ud := c.userData(L)
	L.SetGlobal(userDataName, ud)
}

// ConnectionString return connection string
func (c *connection) connectionString() string {
	return BuildConnectionString(c.host, c.dbname, c.port, c.user, c.password, c.params)
}

// BuildConnectionString create connection string
func BuildConnectionString(host, dbname string, port int, user, password string, params map[string]string) string {
	kvs := make([]string, 0)
	escaper := strings.NewReplacer(` `, `\ `, `'`, `\'`, `\`, `\\`)
	accrue := func(k, v string) {
		if v != "" {
			kvs = append(kvs, k+"="+escaper.Replace(v))
		}
	}
	// prevent random map iteration
	paramKeys := make([]string, 0, len(params))
	for k := range params {
		paramKeys = append(paramKeys, k)
	}
	sort.Strings(paramKeys)
	for _, k := range paramKeys {
		accrue(k, params[k])
	}
	return fmt.Sprintf("host='%s' port=%d dbname='%s' user='%s' password='%s' %s",
		host, port, dbname, user, password, strings.Join(kvs, " "))
}
