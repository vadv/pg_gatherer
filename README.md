# pg_gatherer

project is designed to collect and store statistical data off postgresql to other postgresql.

# Architecture

* target: target database
* manager: database in which information is stored

![Architecture](/img/arch.png)

# Agent

Agent is golang-binary with plugins written in lua ( [vadv/gopher-lua-libs](https://github.com/vadv/gopher-lua-libs) ).

# Deploy

on manager database:

```
psql -h manager -d manager -U postgres -1 -f ./schema/manager/schema.sql
psql -h manager -d manager -U postgres -1 -f ./schema/manager/functions.sql
```

on target database:

```
psql -h target -d target -U postgres -1 -f ./schema/manager/schema.sql
psql -h target -d target -U postgres -1 -f ./schema/manager/plugin*_.sql
```

# Start

```
$ go get github.com/vadv/gopher-lua-libs/cmd/glua-libs
$ vim ./agent/config.yaml
$ glua-libs ./agent/init.lua
```

# Examples

![tables](/img/tables.png)
![other-1](/img/other-1.png)
![other-2](/img/other-2.png)
![graphs](/img/graphs.png)
