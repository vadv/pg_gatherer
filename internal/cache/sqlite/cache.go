package sqlite

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"time"

	// sqlite
	_ "github.com/mattn/go-sqlite3"
)

// cache in sqlite database
// this is a trade-off between memory usage and disk iops usage

const (
	// env value for override default value
	EnvCacheRotateTable = `CACHE_ROTATE_TABLE`
	// default value for rotate tables
	DefaultCacheRotateTable = int64(60 * 60 * 24)
	cacheTableNamePrefix    = `table_`
	createQuery             = `create table if not exists %s (key text primary key, value real, updated_at real)`
)

type Cache struct {
	path string
	db   *sql.DB
}

// New init new cache
func New(path string) (*Cache, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0750); err != nil {
		return nil, err
	}
	result := &Cache{path: path}
	db, err := sql.Open(`sqlite3`, path)
	if err != nil {
		return nil, err
	}
	if _, err := db.Exec(`PRAGMA synchronous = 0`); err != nil {
		return nil, err
	}
	if _, err := db.Exec(`PRAGMA journal_mode = OFF`); err != nil {
		return nil, err
	}
	result.db = db
	go result.rotateOldTablesRoutine()
	return result, nil
}

// TODO: to save syscall, get variable from cache
func (c *Cache) getCacheRotateTable() int64 {
	result := DefaultCacheRotateTable
	envVar := os.Getenv(EnvCacheRotateTable)
	if envVar != `` {
		if value, err := strconv.ParseUint(envVar, 10, 64); err == nil {
			if value > 0 {
				result = int64(value)
			}
		} else {
			log.Printf("[ERROR] cache %s env variable %s has bad value: '%s': '%s' ignoring\n",
				c.path, EnvCacheRotateTable, envVar, err.Error())
		}
	}
	return result
}

// current table name
func (c *Cache) currentTableName() string {
	now := time.Now().Unix()
	return fmt.Sprintf("%s_%d", cacheTableNamePrefix, now-(now%c.getCacheRotateTable()))
}

// prev table name
func (c *Cache) prevTableName() string {
	now := time.Now().Unix()
	return fmt.Sprintf("%s_%d", cacheTableNamePrefix, now-(now%c.getCacheRotateTable())-c.getCacheRotateTable())
}

func (c *Cache) createTable(tableName string) error {
	_, err := c.db.Exec(fmt.Sprintf(createQuery, tableName))
	return err
}
