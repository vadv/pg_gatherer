package main

import "github.com/vadv/pg_gatherer/internal/plugins"

// Config represent configuration of plugins
type Config struct {
	PluginsDir string               `yaml:"plugins_dir"`
	CacheDir   string               `yaml:"cache_dir"`
	Hosts      []HostConfigurations `yaml:"hosts"`
}

// HostConfigurations represent configurations of hosts
type HostConfigurations struct {
	Host    string              `yaml:"host"`
	Plugins []string            `yaml:"plugins,omitempty"`
	Manager *plugins.Connection `yaml:"manager"`
	Agent   *plugins.Connection `yaml:"agent"`
}
