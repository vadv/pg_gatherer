package plugins

import (
	"log"
	"sync"
	"time"
)

// pool of plugins
type pool struct {
	mutex          sync.Mutex
	hosts          map[string]*pluginsFoHost
	rootDir        string
	globalCacheDir string
}

// pluginsFoHost list of plugins for host
type pluginsFoHost struct {
	manager *Connection
	conn    *Connection
	plugins []*plugin
}

// NewPool return new pool
func NewPool(rootDir string, globalCacheDir string) *pool {
	result := &pool{
		hosts:          make(map[string]*pluginsFoHost, 0),
		rootDir:        rootDir,
		globalCacheDir: globalCacheDir,
	}
	go result.supervisor()
	return result
}

func (p *pool) supervisor() error {
	for {
		time.Sleep(time.Second)
		p.mutex.Lock()
		for host, pls := range p.hosts {
			for _, pl := range pls.plugins {
				running, plErr := pl.check()
				if !running {
					log.Printf("[INFO] host: %s, plugin: %s was not running, start it\n",
						host, pl.config.host)
					if plErr != nil {
						log.Printf("[ERROR] host: %s, plugin: %s has error: %s\n",
							host, pl.config.host, plErr.Error())
					}
					if err := pl.prepareState(); err == nil {
						go pl.execute()
					} else {
						log.Printf("[ERROR] host: %s, plugin: %s can't start: %s\n",
							host, pl.config.host, err.Error())
					}
				}
			}
		}
		p.mutex.Unlock()
	}
}

// AddHost add new host
func (p *pool) AddHost(host string, conn *Connection, manager *Connection) {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	if _, ok := p.hosts[host]; !ok {
		p.hosts[host] = &pluginsFoHost{
			manager: manager,
			conn:    conn,
			plugins: make([]*plugin, 0),
		}
	}
}

// AddPluginToHost add plugin to host
func (p *pool) AddPluginToHost(pluginName, host string) error {
	plConfig := &pluginConfig{
		host:           host,
		rootDir:        p.rootDir,
		pluginName:     pluginName,
		globalCacheDir: p.globalCacheDir,
		db:             p.hosts[host].conn,
		manager:        p.hosts[host].manager,
	}
	pl, err := createPlugin(plConfig)
	if err != nil {
		return err
	}
	p.mutex.Lock()
	p.hosts[host].plugins = append(p.hosts[host].plugins, pl)
	p.mutex.Unlock()
	if errPrepare := pl.prepareState(); errPrepare != nil {
		return errPrepare
	}
	return nil
}
