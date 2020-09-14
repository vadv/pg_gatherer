package sqlite

import (
	"context"
	"fmt"
	"log"
	"strconv"
	"strings"
	"time"
)

const (
	listTablesQuery = `
select
	name
from sqlite_master
	where type = 'table' and name like '%%_%%' order by name desc;`
)

func (c *Cache) rotateOldTablesRoutine() {
	for {
		if err := c.rotateOldTables(); err != nil {
			log.Printf("[ERROR] cache %s rotate old tables: %s\n", c.path, err.Error())
			time.Sleep(100 * time.Millisecond)
			continue
		}
		time.Sleep(time.Second * time.Duration(c.getCacheRotateTable()/2))
	}
}

func (c *Cache) rotateOldTables() error {
	time.Sleep(100 * time.Millisecond)
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()
	rows, err := c.db.QueryContext(ctx, listTablesQuery)
	if err != nil {
		return err
	}
	defer rows.Close()
	deadline := time.Now().Unix() - 2*c.getCacheRotateTable()
	for rows.Next() {
		tableName := ""
		errScan := rows.Scan(&tableName)
		if errScan != nil {
			return errScan
		}
		if timeSlice := strings.Split(tableName, "_"); len(timeSlice) > 0 {
			timeStr := timeSlice[len(timeSlice)-1]
			t, err := strconv.ParseInt(timeStr, 10, 64)
			if err == nil {
				if deadline > t {
					log.Printf("[INFO] cache drop table: %#v\n", tableName)
					_, errExec := c.db.Exec(fmt.Sprintf(`drop table %#v`, tableName))
					if errExec != nil {
						return errExec
					}
					c.tableMutex.Lock()
					delete(c.tables, tableName)
					c.tableMutex.Unlock()
				}
			}
		}
	}
	return rows.Err()
}
