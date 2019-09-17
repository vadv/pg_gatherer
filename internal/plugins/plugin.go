package plugins

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"github.com/vadv/pg_gatherer/internal/cache"

	"github.com/vadv/pg_gatherer/internal/manager"

	"github.com/vadv/pg_gatherer/internal/connection"

	libs "github.com/vadv/gopher-lua-libs"

	lua "github.com/yuin/gopher-lua"
)

// Connection to PostgreSQL
type Connection struct {
	Host     string
	DBName   string
	Port     int
	UserName string
	Password string
	Params   map[string]string
}

// plugin struct
type plugin struct {
	mutex      sync.Mutex
	config     *pluginConfig
	state      *lua.LState
	cancelFunc context.CancelFunc
	fileName   string
	running    bool
	err        error
}

// pluginConfig configures plugin
type pluginConfig struct {
	host           string // host name for manager
	rootDir        string // root directory of plugins
	pluginName     string // directory name of plugin
	globalCacheDir string // cache directory
	db             *Connection
	manager        *Connection
}

func createPlugin(config *pluginConfig) (*plugin, error) {
	if config.db == nil {
		return nil, fmt.Errorf("empty db info")
	}
	if config.manager == nil {
		return nil, fmt.Errorf("empty manager info")
	}
	if config.host == `` {
		return nil, fmt.Errorf("empty host info")
	}
	result := &plugin{
		config: config,
	}
	// try to find in embedded
	if _, err := os.Stat(filepath.Join(config.rootDir, "embedded", config.pluginName, "plugin.lua")); err == nil {
		result.fileName = filepath.Join(config.rootDir, "embedded", config.pluginName, "plugin.lua")
	}
	// try to find in main place
	if _, err := os.Stat(filepath.Join(config.rootDir, config.pluginName, "plugin.lua")); err == nil {
		result.fileName = filepath.Join(config.rootDir, config.pluginName, "plugin.lua")
	}
	if result.fileName == "" {
		return nil, fmt.Errorf("plugin not found")
	}
	return result, nil
}

// prepareState prepare plugin to start
func (p *plugin) prepareState() error {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	p.running = false
	p.err = nil
	state := lua.NewState()
	ctx, cancelFunc := context.WithCancel(context.Background())
	state.SetContext(ctx)
	libs.Preload(state)
	if err := state.DoFile(filepath.Join(p.config.rootDir, "init.lua")); err != nil {
		return fmt.Errorf("while load init.lua: %s", err.Error())
	}
	// connection
	connection.Preload(state)
	connection.New(state, `connection`, p.config.db.Host, p.config.db.DBName,
		p.config.db.UserName, p.config.db.Password, p.config.db.Port, p.config.db.Params)
	// manager
	manager.Preload(state)
	manager.New(state, `manager`, p.config.host, connection.BuildConnectionString(p.config.manager.Host,
		p.config.manager.DBName, p.config.manager.Port, p.config.manager.UserName, p.config.manager.Password,
		p.config.manager.Params))
	// cache
	cache.Preload(state)
	if err := cache.NewSqlite(state, `cache`,
		filepath.Join(p.config.globalCacheDir, p.config.host, p.config.pluginName, "cache.sqlite")); err != nil {
		return err
	}
	p.state = state
	p.cancelFunc = cancelFunc
	return nil
}

// Execute plugin
func (p *plugin) execute() {
	// set running
	p.mutex.Lock()
	p.running = true
	p.mutex.Unlock()
	// set err
	err := p.state.DoFile(p.fileName)
	p.mutex.Lock()
	p.err = err
	// set not running
	p.running = false
	p.mutex.Unlock()
}

// Stop plugin
func (p *plugin) stop() {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	p.cancelFunc()
}

// Check plugin status
func (p *plugin) check() (running bool, err error) {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	return p.running, p.err
}
