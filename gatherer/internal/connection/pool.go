package connection

import (
	"database/sql"
	"sync"
)

var (
	connectionPool = &connPool{
		mutex: sync.Mutex{},
		pool:  make(map[string]*sql.DB),
	}
	maxOpenConns = uint(5)
)

// SetMaxOpenConns set max open connections
func SetMaxOpenConns(i uint) {
	maxOpenConns = i
	connectionPool.mutex.Lock()
	defer connectionPool.mutex.Unlock()
	for _, db := range connectionPool.pool {
		db.SetMaxOpenConns(int(maxOpenConns))
	}
}

type connPool struct {
	mutex sync.Mutex
	pool  map[string]*sql.DB
}

func newPostgresConnection(connectionString string) (*sql.DB, error) {
	db, err := sql.Open(`postgres`, connectionString)
	if err != nil {
		return nil, err
	}
	db.SetMaxIdleConns(1)
	db.SetMaxOpenConns(int(maxOpenConns))
	return db, err
}

// get sql.DB from connection pool
func getDBFromPool(c *connection) (*sql.DB, error) {
	connectionPool.mutex.Lock()
	defer connectionPool.mutex.Unlock()
	c.mutexAddDB.Lock()
	defer c.mutexAddDB.Unlock()
	if db, ok := connectionPool.pool[c.connectionString()]; ok {
		return db, nil
	} else {
		// open
		newDB, err := newPostgresConnection(c.connectionString())
		if err != nil {
			return nil, err
		}
		// store
		connectionPool.pool[c.connectionString()] = newDB
		return newDB, nil
	}
}
