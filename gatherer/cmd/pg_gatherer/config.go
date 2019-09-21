package main

import (
	"fmt"

	"github.com/vadv/pg_gatherer/gatherer/internal/plugins"
)

// Config represent configuration of plugins
type Config struct {
	PluginsDir string                        `yaml:"plugins_dir"`
	CacheDir   string                        `yaml:"cache_dir"`
	Hosts      map[string]HostConfigurations `yaml:"hosts"`
}

// HostConfigurations represent configurations of hosts
type HostConfigurations struct {
	Plugins     []string                       `yaml:"plugins,omitempty"`
	Connections map[string]*plugins.Connection `yaml:"connections"`
}

func (c *Config) validate() error {
	if len(c.Hosts) == 0 {
		return fmt.Errorf("`hosts` is empty")
	}
	for _, h := range c.Hosts {
		if len(h.Plugins) == 0 {
			return fmt.Errorf("plugins is empty for host: %s", h.Host)
		}
	}
	return nil
}
