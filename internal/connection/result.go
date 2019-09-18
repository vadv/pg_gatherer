package connection

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/lib/pq"
	lua "github.com/yuin/gopher-lua"
)

// queryResult is sql-query result
type queryResult struct {
	Rows    *lua.LTable
	Columns *lua.LTable
}

func processQuery(L *lua.LState, db *sql.DB, ctx context.Context, query string, args ...interface{}) (*queryResult, error) {
	tx, err := getTx(db, ctx)
	if err != nil {
		return nil, err
	}
	sqlRows, err := tx.Query(query, args...)
	defer tx.Commit()
	return parseRows(sqlRows, L)
}

func getTx(db *sql.DB, ctx context.Context) (*sql.Tx, error) {
	tx, err := db.BeginTx(ctx, &sql.TxOptions{
		Isolation: sql.LevelReadCommitted,
		ReadOnly:  true,
	})
	if err != nil {
		return nil, err
	}
	return tx, nil
}

func parseRows(sqlRows *sql.Rows, L *lua.LState) (*queryResult, error) {
	cols, err := sqlRows.Columns()
	if err != nil {
		return nil, err
	}
	columns := L.CreateTable(len(cols), 1)
	for _, col := range cols {
		columns.Append(lua.LString(col))
	}
	luaRows := L.CreateTable(0, len(cols))
	rowCount := 1
	for sqlRows.Next() {
		col := make([]interface{}, len(cols))
		pointers := make([]interface{}, len(cols))
		for i := range col {
			pointers[i] = &col[i]
		}
		errScan := sqlRows.Scan(pointers...)
		if errScan != nil {
			return nil, errScan
		}
		luaRow := L.CreateTable(0, len(cols))
		for i := range cols {
			valueP := pointers[i].(*interface{})
			value := *valueP
			switch converted := value.(type) {
			case bool:
				luaRow.RawSetInt(i+1, lua.LBool(converted))
			case float64:
				luaRow.RawSetInt(i+1, lua.LNumber(converted))
			case int64:
				luaRow.RawSetInt(i+1, lua.LNumber(converted))
			case []uint8:
				strArr := make([]string, 0)
				pqArr := pq.Array(&strArr)
				if errConv := pqArr.Scan(converted); errConv != nil {
					// todo: new type of array
					luaRow.RawSetInt(i+1, lua.LString(converted))
				} else {
					tbl := L.NewTable()
					for _, v := range strArr {
						tbl.Append(lua.LString(v))
					}
					luaRow.RawSetInt(i+1, tbl)
				}
			case string:
				luaRow.RawSetInt(i+1, lua.LString(converted))
			case time.Time:
				tt := float64(converted.UTC().UnixNano()) / float64(time.Second)
				luaRow.RawSetInt(i+1, lua.LNumber(tt))
			case nil:
				luaRow.RawSetInt(i+1, lua.LNil)
			default:
				return nil, fmt.Errorf("unknown type (value: `%#v`, converted: `%#v`)\n", value, converted)
			}
		}
		luaRows.RawSet(lua.LNumber(rowCount), luaRow)
		rowCount++
	}
	return &queryResult{
		Rows:    luaRows,
		Columns: columns,
	}, nil
}
