package connection

import (
	"context"
	"database/sql"
	"sync"
	"time"
)

const (
	queryGetAllHost            = `select name from host`
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
	// insert
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	tx, errTx := db.BeginTx(ctx, &sql.TxOptions{
		Isolation: sql.LevelReadCommitted,
		ReadOnly:  false,
	})
	if errTx != nil {
		return errTx
	}
	defer tx.Commit()
	_, err := tx.Exec(queryCreateHostOfNotExists, host)
	if err == nil {
		connectionPool.hostsCache[c.connectionString()][host] = true
	}
	// get all hosts
	rows, err := tx.Query(queryGetAllHost)
	if err != nil {
		return err
	}
	defer rows.Close()
	for rows.Next() {
		overHost := ""
		if errScan := rows.Scan(&overHost); errScan != nil {
			return errScan
		}
		connectionPool.hostsCache[c.connectionString()][overHost] = true
	}
	return err
}
