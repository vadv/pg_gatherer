package connection

import (
	"fmt"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

type metric struct {
	host         string
	plugin       string
	snapshot     int64
	valueInteger *int64
	valueFloat64 *float64
	valueJson    *string
}

func parseMetric(host string, table *lua.LTable) (*metric, error) {
	m := &metric{host: host}
	var err error
	table.ForEach(func(k lua.LValue, v lua.LValue) {
		switch strings.ToLower(k.String()) {
		case `host`, `hostname`:
			m.host = v.String()
		case `plugin`:
			m.plugin = v.String()
		case `snapshot`:
			if v.Type() != lua.LTNumber {
				err = fmt.Errorf("`snapshot` must be number")
				return
			}
			m.snapshot = int64(v.(lua.LNumber))
		case `json`, `jsonb`, `value_json`, `value_jsonb`:
			value := v.String()
			m.valueJson = &value
		case `int`, `integer`, `bigint`:
			if v.Type() != lua.LTNumber {
				err = fmt.Errorf("`int` must be number")
				return
			}
			n := int64(v.(lua.LNumber))
			m.valueInteger = &n
		case `float`, `float64`:
			if v.Type() != lua.LTNumber {
				err = fmt.Errorf("`float` must be number")
				return
			}
			n := float64(v.(lua.LNumber))
			m.valueFloat64 = &n
		}
	})
	if err != nil {
		return nil, err
	}
	if m.host == `` {
		return nil, fmt.Errorf("empty `host` info")
	}
	if m.plugin == `` {
		return nil, fmt.Errorf("empty `plugin` info")
	}
	if m.valueInteger == nil && m.valueFloat64 == nil && m.valueJson == nil {
		return nil, fmt.Errorf("empty value")
	}
	// lua `[]` -> json `{}`
	if m.valueJson != nil {
		valueJson := *m.valueJson
		if valueJson == `[]` {
			valueJson = `{}`
			m.valueJson = &valueJson
		}
	}
	return m, err
}
