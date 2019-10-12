package prometheus

import "sync"

var registeredMetrics = newPrometheusMetricList()

type prometheusMetricList struct {
	lock  *sync.Mutex
	cache map[string]*luaMetric
}

func newPrometheusMetricList() *prometheusMetricList {
	return &prometheusMetricList{
		lock:  &sync.Mutex{},
		cache: make(map[string]*luaMetric, 0),
	}
}

func (c *prometheusMetricList) get(key string) (*luaMetric, bool) {
	c.lock.Lock()
	defer c.lock.Unlock()
	m, ok := c.cache[key]
	return m, ok
}

func (c *prometheusMetricList) set(key string, m *luaMetric) {
	c.lock.Lock()
	defer c.lock.Unlock()
	c.cache[key] = m
}
