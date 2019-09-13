package sqlite

import (
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
	query := fmt.Sprintf(listTablesQuery, cacheTableNamePrefix)
	rows, err := c.db.Query(query)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		tableName := ""
		err := rows.Scan(&tableName)
		if err != nil {
			return err
		}
		if tableName != c.currentTableName() && tableName != c.prevTableName() {
			log.Printf("[INFO] cache %s rotating old table %s\n", c.path, tableName)
			_, err := c.db.Exec(fmt.Sprintf(`drop table %s`, tableName))
			if err != nil {
				return err
			}
			createdTablesMutex.Lock()
			delete(createdTables, tableName)
			createdTablesMutex.Unlock()
		}
	}
	return rows.Err()
}
