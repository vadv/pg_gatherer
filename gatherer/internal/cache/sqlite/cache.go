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
	DefaultCacheRotateTable = int64(60 * 60 * 2)
	createQuery             = `create table if not exists "%s" (key text primary key, value real, updated_at real)`
)

// Cache sqlite cache
type Cache struct {
	path       string
	prefix     string
	db         *sql.DB
	tables     map[string]bool
	tableMutex sync.Mutex
}

var listOfOpenCaches = &listOfCaches{list: make(map[string]*sql.DB)}

type listOfCaches struct {
	mutex sync.Mutex
	list  map[string]*sql.DB
}

func (c *Cache) getCacheTableNamePrefix() string {
	return c.prefix
}

// New init new cache
func New(path, prefix string) (*Cache, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0750); err != nil {
		return nil, err
	}
	result := &Cache{path: path, prefix: prefix, tables: make(map[string]bool)}
	listOfOpenCaches.mutex.Lock()
	defer listOfOpenCaches.mutex.Unlock()
	db, ok := listOfOpenCaches.list[path]
	if ok {
		result.db = db
		return result, nil
	}
	retries := 0
OpenSqlite:
	if retries > 3 {
		return nil, fmt.Errorf("too many errors while prepare sqlite database")
	}
	// https://github.com/mattn/go-sqlite3/tree/v2.0.3#connection-string
	connectionString := fmt.Sprintf("file:%s?_synchronous=0&_journal_mode=OFF", path)
	newDB, err := sql.Open(`sqlite3`, connectionString)
	if err != nil {
		log.Printf("[ERROR] delete db %#v, because: %#v while open\n", connectionString, err.Error())
		os.RemoveAll(path)
		retries++
		goto OpenSqlite
	}
	if _, testQuery := newDB.Exec(`select 1`); testQuery != nil {
		newDB.Close()
		log.Printf("[ERROR] delete db %#v, because: %#v while exec test query\n", connectionString, testQuery.Error())
		os.RemoveAll(path)
		retries++
		goto OpenSqlite
	}
	newDB.SetMaxOpenConns(10)
	newDB.SetMaxIdleConns(10)
	listOfOpenCaches.list[path] = newDB
	result.db = newDB
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
	return fmt.Sprintf("%s_%d", c.getCacheTableNamePrefix(), now-(now%c.getCacheRotateTable()))
}

// prev table name
func (c *Cache) prevTableName() string {
	now := time.Now().Unix()
	return fmt.Sprintf("%s_%d", c.getCacheTableNamePrefix(), now-(now%c.getCacheRotateTable())-c.getCacheRotateTable())
}

func (c *Cache) createTable(tableName string) error {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	_, err := c.db.ExecContext(ctx, fmt.Sprintf(createQuery, tableName))
	return err
}
