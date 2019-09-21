package plugins

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/vadv/pg_gatherer/gatherer/internal/cache"

	"github.com/vadv/pg_gatherer/gatherer/internal/connection"

	libs "github.com/vadv/gopher-lua-libs"

	lua "github.com/yuin/gopher-lua"
)

// Connection to PostgreSQL
type Connection struct {
	Host     string            `yaml:"host"`
	DBName   string            `yaml:"dbname"`
	Port     int               `yaml:"port"`
	UserName string            `yaml:"username"`
	Password string            `yaml:"password"`
	Params   map[string]string `yaml:"params"`
}

// PluginStatistic represent statistics for plugin
type PluginStatistic struct {
	Host           string
	PluginName     string
	PluginFileName string
	Starts         int
	Errors         int
	LastCheck      int64
	LastError      string
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
	statistics *PluginStatistic
}

// pluginConfig configures plugin
type pluginConfig struct {
	host           string // host name for manager
	rootDir        string // root directory of plugins
	pluginName     string // directory name of plugin
	globalCacheDir string // cache directory
	connections    map[string]*Connection
}

func createPlugin(config *pluginConfig) (*plugin, error) {
	if config.host == `` {
		return nil, fmt.Errorf("empty host info")
	}
	result := &plugin{
		config: config,
		statistics: &PluginStatistic{
			PluginName: config.pluginName,
			Host:       config.host,
		},
	}
	if _, err := os.Stat(filepath.Join(config.rootDir, config.pluginName, "plugin.lua")); err == nil {
		result.fileName = filepath.Join(config.rootDir, config.pluginName, "plugin.lua")
	}
	if result.fileName == "" {
		return nil, fmt.Errorf("plugin.lua file in directory '%s' or 'embedded/%s' in '%s' is not found",
			config.pluginName, config.pluginName, config.rootDir)
	}
	result.statistics.PluginFileName = result.fileName
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
	connection.Preload(state)
	for name, conn := range p.config.connections {
		// connection
		connection.New(state, name, conn.Host, conn.DBName,
			conn.UserName, conn.Password, conn.Port, conn.Params)
	}
	// cache
	cache.Preload(state)
	cachePath := filepath.Join(p.config.globalCacheDir, p.config.host, p.config.pluginName, "cache.sqlite")
	if err := cache.NewSqlite(state, `cache`, cachePath); err != nil {
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
	p.statistics.Starts++
	p.running = true
	p.mutex.Unlock()
	// set err
	err := p.state.DoFile(p.fileName)
	p.mutex.Lock()
	if err != nil {
		p.statistics.Errors++
		p.statistics.LastError = err.Error()
	}
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

// Show statistic for plugin
func (p *plugin) getStatistics() PluginStatistic {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	result := p.statistics
	return *result
}

// update information about plugin check
// need for monitoring that plugin errors was checked
func (p *plugin) updateStatisticCheck() {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	p.statistics.LastCheck = time.Now().Unix()
}
