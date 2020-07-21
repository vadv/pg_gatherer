package connection

import (
	"database/sql"
	"fmt"
	"sync"
	"testing"

	lua "github.com/yuin/gopher-lua"
)

const doAvailableConnections = `
connection:query('select 1')
for _, conn in pairs(connection:available_connections()) do
	conn:query('select 1')
end
`

func TestNew(t *testing.T) {
	wait := sync.WaitGroup{}
	count := 100
	wait.Add(count)
	countOfDatabases := getCountOfDatabases(t)
	SetMaxOpenConns(1)
	for i := 0; i < count; i++ {
		go func() {
			defer wait.Done()
			state := lua.NewState()
			Preload(state)
			params := make(map[string]string)
			params[`fallback_application_name`] = `test`
			params[`connect_timeout`] = `5`
			New(state, `connection`,
				"/tmp", "gatherer", "gatherer", "", 5432, params)
			if err := state.DoString(doAvailableConnections); err != nil {
				panic(fmt.Sprintf("do: %s\n", err.Error()))
			}
		}()
	}
	wait.Wait()
	if *poolDatabasesOpen != int32(countOfDatabases) {
		t.Fatalf("open: %d count: %d\n", *poolDatabasesOpen, countOfDatabases)
	}
	if len(connectionPool.pool) != countOfDatabases {
		t.Fatalf("pool: %#v\n", connectionPool.pool)
	}
	if connections := getCountOfApplicationNameTest(t); connections != countOfDatabases {
		t.Fatalf("databases: %d connections: %d\n", countOfDatabases, connections)
	}
}

func getCountOfDatabases(t *testing.T) int {
	db, err := sql.Open(`postgres`, `host=/tmp dbname=gatherer user=gatherer port=5432`)
	if err != nil {
		t.Fatalf("open: %s\n", err.Error())
	}
	row := db.QueryRow(`select
	count(d.datname)
from
	pg_catalog.pg_database d
where has_database_privilege(d.datname, 'connect') and not d.datistemplate
`)
	defer db.Close()
	var result int
	if errScan := row.Scan(&result); errScan != nil {
		t.Fatalf("scan: %s\n", errScan.Error())
	}
	return result
}

func getCountOfApplicationNameTest(t *testing.T) int {
	db, err := sql.Open(`postgres`, `host=/tmp dbname=gatherer user=gatherer port=5432`)
	if err != nil {
		t.Fatalf("open: %s\n", err.Error())
	}
	row := db.QueryRow(`select count(*) from pg_stat_activity where application_name = 'test'`)
	defer db.Close()
	var result int
	if errScan := row.Scan(&result); errScan != nil {
		t.Fatalf("scan: %s\n", errScan.Error())
	}
	return result
}
