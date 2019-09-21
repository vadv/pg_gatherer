package plugins

import (
	"fmt"
	"log"
	"sync"
	"time"
)

// Pool of plugins
type Pool struct {
	mutex          sync.Mutex
	hosts          map[string]*pluginsForHost
	rootDir        string
	globalCacheDir string
}

// pluginsForHost list of plugins for host
type pluginsForHost struct {
	connections map[string]*Connection
	plugins     []*plugin
}

// NewPool return new Pool
func NewPool(rootDir string, globalCacheDir string) *Pool {
	result := &Pool{
		hosts:          make(map[string]*pluginsForHost, 0),
		rootDir:        rootDir,
		globalCacheDir: globalCacheDir,
	}
	go result.supervisor()
	return result
}

func (p *Pool) supervisor() error {
	for {
		time.Sleep(time.Second)
		p.mutex.Lock()
		for host, pls := range p.hosts {
			for _, pl := range pls.plugins {
				running, plErr := pl.check()
				pl.updateStatisticCheck()
				if !running {
					log.Printf("[INFO] host: %s, plugin: %s was not running, start it\n",
						host, pl.config.pluginName)
					if plErr != nil {
						log.Printf("[ERROR] host: %s, plugin: %s has error: %s\n",
							host, pl.config.pluginName, plErr.Error())
					}
					if err := pl.prepareState(); err == nil {
						go pl.execute()
					} else {
						log.Printf("[ERROR] host: %s, plugin: %s can't start: %s\n",
							host, pl.config.pluginName, err.Error())
					}
				}
			}
		}
		p.mutex.Unlock()
	}
}

// RegisterHost register new host
func (p *Pool) RegisterHost(host string, connections map[string]*Connection) {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	if _, ok := p.hosts[host]; !ok {
		p.hosts[host] = &pluginsForHost{
			connections: connections,
			plugins:     make([]*plugin, 0),
		}
	}
}

// RemoveHostAndPlugins stop all plugins and remove host
func (p *Pool) RemoveHostAndPlugins(host string) {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	for plHostName, pls := range p.hosts {
		if plHostName == host {
			// stop all plugins
			for _, pl := range pls.plugins {
				pl.stop()
			}
			delete(p.hosts, host)
		}
	}
}

// AddPluginToHost add plugin to host
func (p *Pool) AddPluginToHost(pluginName, host string) error {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	// check
	if pls, ok := p.hosts[host]; !ok {
		return fmt.Errorf("host not registered")
	} else {
		for _, pl := range pls.plugins {
			if pl.config.pluginName == pluginName {
				return fmt.Errorf("plugin already registered")
			}
		}
	}
	plConfig := &pluginConfig{
		host:           host,
		rootDir:        p.rootDir,
		pluginName:     pluginName,
		globalCacheDir: p.globalCacheDir,
		connections:    p.hosts[host].connections,
	}
	pl, err := createPlugin(plConfig)
	if err != nil {
		return err
	}
	p.hosts[host].plugins = append(p.hosts[host].plugins, pl)
	if errPrepare := pl.prepareState(); errPrepare != nil {
		return errPrepare
	}
	return nil
}

// StopAndRemovePluginFromHost stop plugin on host
func (p *Pool) StopAndRemovePluginFromHost(pluginName, host string) error {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	// check
	if pls, ok := p.hosts[host]; !ok {
		return fmt.Errorf("host '%s' not registered", host)
	} else {
		var found bool
		for _, pl := range pls.plugins {
			if pl.config.pluginName == pluginName {
				found = true
			}
		}
		if !found {
			return fmt.Errorf("plugin '%s' for host '%s' not found", pluginName, host)
		}
	}
	// stop
	plugins := make([]*plugin, 0)
	for _, pl := range p.hosts[host].plugins {
		if pl.config.pluginName == pluginName {
			pl.stop()
		} else {
			plugins = append(plugins, pl)
		}
	}
	p.hosts[host].plugins = plugins
	return nil
}

// PluginStatisticPerHost statistic information about all host
func (p *Pool) PluginStatisticPerHost() map[string][]PluginStatistic {
	p.mutex.Lock()
	p.mutex.Unlock()
	result := make(map[string][]PluginStatistic, 0)
	for host, pls := range p.hosts {
		if _, ok := result[host]; !ok {
			result[host] = make([]PluginStatistic, 0)
		}
		for _, pl := range pls.plugins {
			result[host] = append(result[host], pl.getStatistics())
		}
	}
	return result
}
