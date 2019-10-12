Creates lua user data `prometheus_metric_ud`.

# Golang

```go
	state := lua.NewState()
	prometheus.Preload(state)
```

# Lua

## local gauge = prometheus:gauge({name="",namespace="",subsystem="",name="",help=""})

Register prometheus `gauge`.

## gauge:set(number), gauge:inc(), gauge:add(1)

Set value to `gauge`.

## local counter = prometheus:counter({name="",namespace="",subsystem="",name="",help=""})

Register prometheus `counter`.

## counter:inc(), counter:add(1)

Set value to `counter`.

## local gauge_vec = prometheus:gauge({name="",namespace="",subsystem="",name="",help="", labels={"label1", "label2"})

Register prometheus `gauge` vector.

## gauge_vec:set(number, {label1="",label2=""}), gauge_vec:inc({label1="",label2=""}), gauge_vec:add(1, {label1="",label2=""})

Set value to `gauge` vector.

## local counter_vec = prometheus:gauge({name="",namespace="",subsystem="",name="",help="", labels={"label1", "label2"})

Register prometheus `counter` vector.

## counter_vec:inc({label1="",label2=""}), counter_vec:add(1, {label1="",label2=""})

Set value to `counter` vector.