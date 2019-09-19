package connection

import (
	"database/sql"
	"sync"
)

var (
	connectionPool      = make(map[string]*sql.DB)
	connectionPoolMutex = sync.Mutex{}
)

func getDBFromPool(c *connection) (*sql.DB, error) {
	connectionPoolMutex.Lock()
	defer connectionPoolMutex.Unlock()
	if db, ok := connectionPool[c.connectionString()]; ok {
		return db, nil
	} else {
		// open
		newDB, err := sql.Open(`postgres`, c.connectionString())
		if err != nil {
			return nil, err
		}
		newDB.SetMaxIdleConns(1)
		newDB.SetMaxOpenConns(5)
		// store
		connectionPool[c.connectionString()] = newDB
		return newDB, nil
	}
}
