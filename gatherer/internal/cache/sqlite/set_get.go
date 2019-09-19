package sqlite

import (
	"database/sql"
	"fmt"
	"time"
)

const (
	setQuery = `
insert
	into %s (key, value, updated_at)
values (?, ?, ?) on conflict (key) do
	update set value=excluded.value, updated_at=excluded.updated_at
`
	getQuery = `select value, updated_at from %s where key = ?`
)

func (c *Cache) checkTableExists(tableName string) error {
	// check to table is created
	c.mutex.Lock()
	defer c.mutex.Unlock()
	if _, ok := c.tables[tableName]; !ok {
		if err := c.createTable(tableName); err != nil {
			return err
		}
		c.tables[tableName] = true
	}
	return nil
}

// Set new value in cache
func (c *Cache) Set(key string, value float64) error {
	if err := c.checkTableExists(c.currentTableName()); err != nil {
		return err
	}
	// query
	_, err := c.db.Exec(fmt.Sprintf(setQuery, c.currentTableName()), key, value, time.Now().Unix())
	return err
}

// get return value, updatedAt, error
func (c *Cache) getFromTable(key, tableName string) (float64, int64, bool, error) {
	if err := c.checkTableExists(tableName); err != nil {
		return 0, 0, false, err
	}
	query := fmt.Sprintf(getQuery, tableName)
	row := c.db.QueryRow(query, key)
	var value, updatedAt float64
	err := row.Scan(&value, &updatedAt)
	if err != nil && err == sql.ErrNoRows {
		return 0, 0, false, nil
	}
	if err != nil {
		return 0, 0, false, err
	}
	return value, int64(updatedAt), true, nil
}

// Get return value, updatedAt, error
// we get data from prev table, if not found key in current
func (c *Cache) Get(key string) (value float64, updatedAt int64, found bool, err error) {
	value, updatedAt, found, err = c.getFromTable(key, c.currentTableName())
	if !found {
		return c.getFromTable(key, c.prevTableName())
	}
	return
}
