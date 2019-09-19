package connection

import (
	"context"
	"database/sql"
	"sync"

	lua "github.com/yuin/gopher-lua"
)

type backgroundQuery struct {
	mutex      sync.Mutex
	running    bool
	tx         *sql.Tx
	sqlRows    *sql.Rows
	query      string
	queryArgs  []interface{}
	err        error
	cancelFunc context.CancelFunc
}

// checkUserDataBackgroundQuery return background_query_ud from lua state
func checkUserDataBackgroundQuery(L *lua.LState, n int) *backgroundQuery {
	ud := L.CheckUserData(n)
	if v, ok := ud.Value.(*backgroundQuery); ok {
		return v
	}
	L.ArgError(n, "background_query_ud expected")
	return nil
}

// create background_query
func runBackgroundQuery(L *lua.LState) int {
	conn := checkUserDataConnection(L, 1)
	sqlQuery := L.CheckString(2)
	args := parseArgs(L, 3)
	ctx, cancelFunc := context.WithCancel(context.Background())
	result := &backgroundQuery{
		running:    true,
		cancelFunc: cancelFunc,
		query:      sqlQuery,
		queryArgs:  args,
	}
	go func(result *backgroundQuery) {

		tx, err := getTx(conn.db, ctx)
		if err != nil {
			result.mutex.Lock()
			result.err = err
			result.running = false
			result.mutex.Unlock()
			return
		}

		result.mutex.Lock()
		result.tx = tx
		result.mutex.Unlock()

		sqlRows, errQuery := tx.Query(result.query, result.queryArgs...)
		if errQuery != nil {
			result.mutex.Lock()
			result.err = errQuery
			result.running = false
			result.mutex.Unlock()
			return
		}

		result.mutex.Lock()
		result.sqlRows = sqlRows
		result.running = false
		result.mutex.Unlock()
	}(result)
	ud := L.NewUserData()
	ud.Value = result
	L.SetMetatable(ud, L.GetTypeMetatable(`background_query_ud`))
	L.Push(ud)
	return 1
}

// cancel background query
func backgroundQueryCancel(L *lua.LState) int {
	ud := checkUserDataBackgroundQuery(L, 1)
	ud.mutex.Lock()
	defer ud.mutex.Unlock()
	ud.cancelFunc()
	return 0
}

// background query is running
func backgroundQueryIsRunning(L *lua.LState) int {
	ud := checkUserDataBackgroundQuery(L, 1)
	ud.mutex.Lock()
	defer ud.mutex.Unlock()
	L.Push(lua.LBool(ud.running))
	return 1
}

// background query result
func backgroundQueryResult(L *lua.LState) int {
	ud := checkUserDataBackgroundQuery(L, 1)
	ud.mutex.Lock()
	defer ud.mutex.Unlock()
	if ud.running {
		L.RaiseError("query already running")
		return 0
	}
	if ud.sqlRows != nil {
		defer ud.sqlRows.Close()
	}
	if ud.tx != nil {
		defer ud.tx.Commit()
	}
	if ud.err != nil {
		L.RaiseError("query has error: %s", ud.err.Error())
		return 0
	}
	execResult, err := parseRows(ud.sqlRows, L)
	if err != nil {
		L.RaiseError("parse query: %s", err.Error())
		return 0
	}
	result := L.NewTable()
	result.RawSetString(`rows`, execResult.Rows)
	result.RawSetString(`columns`, execResult.Columns)
	L.Push(result)
	return 1
}
