package sqlite

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"time"

	// sqlite
	_ "github.com/mattn/go-sqlite3"
)

// cache in sqlite database
// this is a trade-off between memory usage and disk iops usage

const (
	// EnvCacheRotateTable env value for override default value
	EnvCacheRotateTable = `CACHE_ROTATE_TABLE`
	// DefaultCacheRotateTable default value for rotate tables
	DefaultCacheRotateTable = int64(60 * 60 * 24)
	cacheTableNamePrefix    = `table_`
	createQuery             = `create table if not exists %s (key text primary key, value real, updated_at real)`
)

// Cache sqlite cache
type Cache struct {
	path   string
	db     *sql.DB
	tables map[string]bool
	mutex  sync.Mutex
}

var listOfOpenCaches = &listOfCaches{list: make(map[string]*sql.DB, 0)}

type listOfCaches struct {
	mutex sync.Mutex
	list  map[string]*sql.DB
}

// New init new cache
func New(path string) (*Cache, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0750); err != nil {
		return nil, err
	}
	result := &Cache{path: path, tables: make(map[string]bool, 0)}
	listOfOpenCaches.mutex.Lock()
	defer listOfOpenCaches.mutex.Unlock()
	db, ok := listOfOpenCaches.list[path]
	if ok {
		result.db = db
		return result, nil
	} else {
		newDB, err := sql.Open(`sqlite3`, path)
		if err != nil {
			return nil, err
		}
		if _, errSync := newDB.Exec(`PRAGMA synchronous = 0`); errSync != nil {
			newDB.Close()
			return nil, errSync
		}
		if _, errJournal := newDB.Exec(`PRAGMA journal_mode = OFF`); errJournal != nil {
			newDB.Close()
			return nil, errJournal
		}
		newDB.SetMaxOpenConns(1)
		newDB.SetMaxIdleConns(1)
		listOfOpenCaches.list[path] = newDB
		result.db = newDB
		go result.rotateOldTablesRoutine()
		return result, nil
	}
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
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	_, err := c.db.ExecContext(ctx, fmt.Sprintf(createQuery, tableName))
	return err
}
