package connection

import (
	"database/sql"
	"fmt"

	lua "github.com/yuin/gopher-lua"
)

// connection to PostgreSQL
type connection struct {
	db       *sql.DB
	Host     string
	DBName   string
	Port     int
	User     string
	Password string
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
func New(L *lua.LState, userDataName string, host, dbname string, port int, user, password string) {
	c := &connection{
		Host:     host,
		DBName:   dbname,
		Port:     port,
		User:     user,
		Password: password,
	}
	ud := c.userData(L)
	L.SetGlobal(userDataName, ud)
}

// ConnectionString return connection string
func (c *connection) connectionString() string {
	return fmt.Sprintf("host='%s' port=%d dbname='%s' user='%s' password='%s'",
		c.Host, c.Port, c.DBName, c.User, c.Password)
}
