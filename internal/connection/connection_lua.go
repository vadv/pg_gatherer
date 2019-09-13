package connection

import (
	lua "github.com/yuin/gopher-lua"
)

const (
	listConnections = `select
	d.datname
from
	pg_catalog.pg_database d
where has_database_privilege(d.datname, 'connect') and not d.datistemplate
`
)

// userData represent connection in lua state
func (c *connection) userData(L *lua.LState) *lua.LUserData {
	ud := L.NewUserData()
	if c.db == nil {
		db, err := getDBFromPool(c)
		if err != nil {
			L.RaiseError("open connection error: %s", err.Error())
			return nil
		}
		c.db = db
	}
	ud.Value = c
	L.SetMetatable(ud, L.GetTypeMetatable(`connection_ud`))
	return ud
}

// checkUserDataConnection return connection from lua state
func checkUserDataConnection(L *lua.LState, n int) *connection {
	ud := L.CheckUserData(n)
	if v, ok := ud.Value.(*connection); ok {
		return v
	}
	L.ArgError(n, "connection_ud expected")
	return nil
}

// query execute query from connection
func query(L *lua.LState) int {
	ud := checkUserDataConnection(L, 1)
	query := L.CheckString(2)
	args := make([]interface{}, 0)
	if count := L.GetTop(); count > 2 {
		for n := 3; n <= count; n++ {
			arg := L.CheckAny(n)
			switch arg.Type() {
			case lua.LTString:
				args = append(args, L.CheckString(n))
			case lua.LTNumber:
				args = append(args, float64(L.CheckNumber(n)))
			case lua.LTBool:
				args = append(args, L.CheckBool(n))
			default:
				L.Push(lua.LNil)
				L.Push(lua.LString("unsupported type for query args"))
				return 2
			}
		}
	}
	queryResult, err := processQuery(L, ud.db, query, args...)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	result := L.NewTable()
	result.RawSetString(`rows`, queryResult.Rows)
	result.RawSetString(`columns`, queryResult.Columns)
	L.Push(result)
	return 1
}

// availableConnections push list of all connections
func availableConnections(L *lua.LState) int {
	ud := checkUserDataConnection(L, 1)
	sqlRows, err := ud.db.Query(listConnections)
	if err != nil {
		L.Push(lua.LNil)
		L.Push(lua.LString(err.Error()))
		return 2
	}
	defer sqlRows.Close()
	result := L.NewTable()
	for sqlRows.Next() {
		dbname := ""
		if err := sqlRows.Scan(&dbname); err != nil {
			L.Push(lua.LNil)
			L.Push(lua.LString(err.Error()))
			return 2
		}
		c := &connection{
			Host:     ud.Host,
			DBName:   dbname,
			Port:     ud.Port,
			User:     ud.User,
			Password: ud.Password,
		}
		newUd := c.userData(L)
		result.Append(newUd)
	}
	L.Push(result)
	return 1
}
