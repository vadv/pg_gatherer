package sqlite

import (
	"context"
	"fmt"
	"log"
	"time"
)

const (
	listTablesQuery = `
select
	name
from sqlite_master
	where type = 'table' and name like '%s_%%' order by name;`
)

func (c *Cache) rotateOldTablesRoutine() {
	for {
		if err := c.rotateOldTables(); err != nil {
			log.Printf("[ERROR] cache %s rotate old tables: %s\n", c.path, err.Error())
		}
		time.Sleep(time.Second * time.Duration(c.getCacheRotateTable()/2))
	}
}

func (c *Cache) rotateOldTables() error {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	query := fmt.Sprintf(listTablesQuery, c.getCacheTableNamePrefix())
	rows, err := c.db.QueryContext(ctx, query)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		tableName := ""
		errScan := rows.Scan(&tableName)
		if errScan != nil {
			return errScan
		}
		if tableName != c.currentTableName() && tableName != c.prevTableName() {
			_, errExec := c.db.Exec(fmt.Sprintf(`drop table %#v`, tableName))
			if errExec != nil {
				return errExec
			}
			c.tableMutex.Lock()
			delete(c.tables, tableName)
			c.tableMutex.Unlock()
		}
	}
	return rows.Err()
}
