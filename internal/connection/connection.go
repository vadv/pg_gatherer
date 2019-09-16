package connection

import (
	"database/sql"
	"fmt"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

// connection to PostgreSQL
type connection struct {
	db       *sql.DB
	host     string
	dbname   string
	port     int
	user     string
	password string
	params   map[string]string
}

// Preload is the preloader of user data connection_ud.
func Preload(L *lua.LState) int {
	connectionUd := L.NewTypeMetatable(`connection_ud`)
	L.SetGlobal(`connection_ud`, connectionUd)
	L.SetField(connectionUd, "__index", L.SetFuncs(L.NewTable(), map[string]lua.LGFunction{
		"query":                 query,
		"available_connections": availableConnections,
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
	kvs := make([]string, 0)
	escaper := strings.NewReplacer(` `, `\ `, `'`, `\'`, `\`, `\\`)
	accrue := func(k, v string) {
		if v != "" {
			kvs = append(kvs, k+"="+escaper.Replace(v))
		}
	}
	for k, v := range c.params {
		accrue(k, v)
	}
	return fmt.Sprintf("host='%s' port=%d dbname='%s' user='%s' password='%s' %s",
		c.host, c.port, c.dbname, c.user, c.password, strings.Join(kvs, " "))
}
