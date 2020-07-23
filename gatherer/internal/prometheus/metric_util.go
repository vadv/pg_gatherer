package prometheus

import (
	"fmt"
	"sort"
	"strings"

	"github.com/prometheus/client_golang/prometheus"

	lua "github.com/yuin/gopher-lua"
)

const (
	// DefaultNamespace is default namespace for prometheus
	DefaultNamespace = `pg`
	// DefaultSubsystem is default subsystem for prometheus
	DefaultSubsystem = `gatherer`
)

// convert lua table to luaPrometheusMetricConfig
func luaTableToMetricConfig(config *lua.LTable, L *lua.LState) *luaPrometheusMetricConfig {
	result := &luaPrometheusMetricConfig{
		namespace: DefaultNamespace,
		subsystem: DefaultSubsystem,
	}
	config.ForEach(func(k lua.LValue, v lua.LValue) {
		switch k.String() {
		case `namespace`:
			result.namespace = v.String()
		case `subsystem`:
			result.subsystem = v.String()
		case `name`:
			result.name = v.String()
		case `help`:
			result.help = v.String()
		case `labels`:
			tbl, ok := v.(*lua.LTable)
			if !ok {
				L.ArgError(1, "labels must be string")
			}
			result.labels = luaTableToSlice(tbl)
		}
	})
	return result
}

// convert lua table to sorted []string
func luaTableToSlice(tbl *lua.LTable) []string {
	result := make([]string, 0)
	tbl.ForEach(func(k lua.LValue, v lua.LValue) {
		result = append(result, v.String())
	})
	sort.Strings(result)
	return result
}

func (m *luaPrometheusMetricConfig) hasLabels() bool {
	return len(m.labels) > 0
}

func (m *luaPrometheusMetricConfig) getKey() string {
	return fmt.Sprintf("%s_%s_%s", m.namespace, m.subsystem, m.name)
}

func (m *luaPrometheusMetricConfig) equal(m2 *luaPrometheusMetricConfig) bool {
	if m.getKey() != m2.getKey() {
		return false
	}
	if (len(m.labels) != 0) && (len(m2.labels) != 0) {
		// because labels sorted
		return strings.Join(m.labels, "") == strings.Join(m2.labels, "")
	}
	return true
}

func (m *luaPrometheusMetricConfig) getGaugeOpts() prometheus.GaugeOpts {
	return prometheus.GaugeOpts{
		Namespace: m.namespace,
		Subsystem: m.subsystem,
		Name:      m.name,
		Help:      m.help,
	}
}

func (m *luaPrometheusMetricConfig) getCounterOpts() prometheus.CounterOpts {
	return prometheus.CounterOpts{
		Namespace: m.namespace,
		Subsystem: m.subsystem,
		Name:      m.name,
		Help:      m.help,
	}
}

//convert lua table to prometheus.Label
func luaTableToPrometheusLabels(tbl *lua.LTable) prometheus.Labels {
	result := make(map[string]string)
	tbl.ForEach(func(k lua.LValue, v lua.LValue) {
		result[k.String()] = v.String()
	})
	return result
}
