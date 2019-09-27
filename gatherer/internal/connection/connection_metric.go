package connection

import (
	"context"
	"time"

	lua "github.com/yuin/gopher-lua"
)

const (
	queryInsert = `
insert into metric
	(host, plugin, snapshot, value_bigint, value_double, value_jsonb)
	values (md5($1)::uuid, md5($2)::uuid, $3, $4, $5, $6::jsonb)
`
)

func insertMetric(L *lua.LState) int {
	ud := checkUserDataConnection(L, 1)
	table := L.CheckTable(2)
	m, err := parseMetric(table)
	if err != nil {
		L.RaiseError("parse metric: %s", err.Error())
		return 0
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, err = ud.db.ExecContext(ctx, queryInsert,
		m.host, m.plugin, m.snapshot, m.valueInteger, m.valueFloat64, m.valueJson)
	if err != nil {
		L.RaiseError("save metric: %s", err.Error())
	}
	return 0
}
