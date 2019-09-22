package connection

import (
	"context"
	"database/sql"
	"sync"
	"time"
)

const (
	queryCreateHostOfNotExists = `insert into host (name) values ($1) on conflict do nothing;`
)

var connectionPool = &connPool{
	mutex: sync.Mutex{},
	pool:  make(map[string]*sql.DB),
	// map[connection string]map[host]bool
	hostsCache: make(map[string]map[string]bool),
}

type connPool struct {
	mutex      sync.Mutex
	pool       map[string]*sql.DB
	hostsCache map[string]map[string]bool
}

func newPostgresConnection(connectionString string) (*sql.DB, error) {
	db, err := sql.Open(`postgres`, connectionString)
	if err != nil {
		return nil, err
	}
	db.SetMaxIdleConns(1)
	db.SetMaxOpenConns(5)
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

// create host in sql.DB
func createHostIfNotExists(c *connection, host string) error {
	connectionPool.mutex.Lock()
	defer connectionPool.mutex.Unlock()
	db, dbFound := connectionPool.pool[c.connectionString()]
	if !dbFound {
		newDB, err := newPostgresConnection(c.connectionString())
		if err != nil {
			return err
		}
		// store
		connectionPool.pool[c.connectionString()] = newDB
		db = newDB
	}
	if _, ok := connectionPool.hostsCache[c.connectionString()]; !ok {
		connectionPool.hostsCache[c.connectionString()] = make(map[string]bool)
	}
	if _, ok := connectionPool.hostsCache[c.connectionString()][host]; ok {
		return nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	_, err := db.ExecContext(ctx, queryCreateHostOfNotExists, host)
	if err == nil {
		connectionPool.hostsCache[c.connectionString()][host] = true
	}
	return err
}
