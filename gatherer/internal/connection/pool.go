package connection

import (
	"database/sql"
	"sync"
	"sync/atomic"
)

var (
	connectionPool    *connPool
	poolDatabasesOpen *int32 // for testing
	maxOpenConns      uint
)

func init() {
	maxOpenConns = 5
	connectionPool = &connPool{
		mutex: sync.Mutex{},
		pool:  make(map[string]*sql.DB),
	}
	zero := int32(0)
	poolDatabasesOpen = &zero
}

// SetMaxOpenConns set max open connections
func SetMaxOpenConns(i uint) {
	maxOpenConns = i
	connectionPool.mutex.Lock()
	defer connectionPool.mutex.Unlock()
	for _, db := range connectionPool.pool {
		db.SetMaxOpenConns(int(maxOpenConns))
		db.SetMaxIdleConns(int(maxOpenConns))
	}
}

type connPool struct {
	mutex sync.Mutex
	pool  map[string]*sql.DB
}

func newPostgresConnection(connectionString string) (*sql.DB, error) {
	atomic.AddInt32(poolDatabasesOpen, 1)
	db, err := sql.Open(`gatherer-pq`, connectionString)
	if err != nil {
		return nil, err
	}
	db.SetMaxIdleConns(int(maxOpenConns))
	db.SetMaxOpenConns(int(maxOpenConns))
	return db, err
}

// get sql.DB from connection pool
func getDBFromPool(c *connection) (*sql.DB, error) {
	connectionPool.mutex.Lock()
	defer connectionPool.mutex.Unlock()
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
