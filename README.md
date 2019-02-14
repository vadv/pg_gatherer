# PG_GATHERER

project is designed to collect and store statistical data on postgresql.

# Architecture

agent: target database
manager: database in which information is stored

# Deploy

on manager database:

```
psql -h manager -d manager -U postgres -1 -f ./schema/manager/schema.sql
psql -h manager -d manager -U postgres -1 -f ./schema/manager/functions.sql
```

on target database:

```
psql -h agent -d agent -U postgres -1 -f ./schema/manager/schema.sql
psql -h agent -d agent -U postgres -1 -f ./schema/manager/plugin*_.sql
```

# Start

```
$ go get github.com/vadv/gopher-lua-libs/cmd/glua-libs
$ vim ./agent/config.yaml
$ glua-libs ./agent/init.lua
```
