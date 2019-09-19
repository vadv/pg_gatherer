package manager

import (
	lua "github.com/yuin/gopher-lua"
)

const (
	queryInsert = `
insert into metric
	(host, plugin, snapshot, value_bigint, value_double, value_jsonb)
	values (md5($1)::uuid, md5($2)::uuid, $3, $4, $5, $6::jsonb)
`
)

// checkUserDataManager return connection from lua state
func checkUserDataManager(L *lua.LState, n int) *manager {
	ud := L.CheckUserData(n)
	if v, ok := ud.Value.(*manager); ok {
		return v
	}
	L.ArgError(n, "manager_ud expected")
	return nil
}

func setMetric(L *lua.LState) int {
	ud := checkUserDataManager(L, 1)
	table := L.CheckTable(2)
	m, err := parseMetric(ud.host, table)
	if err != nil {
		L.RaiseError("parse metric: %s", err.Error())
	}
	_, err = ud.db.Exec(queryInsert,
		m.host, m.plugin, m.snapshot, m.valueInteger, m.valueFloat64, m.valueJson)
	if err != nil {
		L.RaiseError("save metric: %s", err.Error())
	}
	return 0
}
