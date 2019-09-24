package connection

import (
	"fmt"
	"strings"

	lua "github.com/yuin/gopher-lua"
)

type metric struct {
	host         string
	plugin       string
	snapshot     *int64
	valueInteger *int64
	valueFloat64 *float64
	valueJson    *string
}

func parseMetric(table *lua.LTable) (*metric, error) {
	m := &metric{}
	var err error
	table.ForEach(func(k lua.LValue, v lua.LValue) {
		switch strings.ToLower(k.String()) {
		case `host`:
			m.host = v.String()
		case `plugin`:
			m.plugin = v.String()
		case `snapshot`:
			if v.Type() != lua.LTNumber {
				err = fmt.Errorf("`snapshot` must be number")
				return
			}
			n := int64(v.(lua.LNumber))
			m.snapshot = &n
		case `json`:
			value := v.String()
			m.valueJson = &value
		case `int`:
			if v.Type() != lua.LTNumber {
				err = fmt.Errorf("`int` must be number")
				return
			}
			n := int64(v.(lua.LNumber))
			m.valueInteger = &n
		case `float`:
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
	// lua `[]` -> json `{}`
	if m.valueJson != nil {
		valueJson := *m.valueJson
		if valueJson == `[]` {
			valueJson = `{}`
			m.valueJson = &valueJson
		}
	}
	if m.valueInteger == nil && m.valueFloat64 == nil && (m.valueJson == nil || *m.valueJson == `{}`) {
		return nil, fmt.Errorf("empty value")
	}
	return m, err
}
