[![Travis](https://travis-ci.org/vadv/pg_gatherer.svg)](https://travis-ci.org/vadv/pg_gatherer)

## Config

Config example:

```yaml
plugins_dir: ./plugins
cache_dir: /tmp/gatherer

hosts:
  - host: gatherer
    plugins:
      - activity
    manager:
      host: /tmp
      dbname: gatherer
      username: gatherer
      port: 5432
    agent:
      host: /tmp
      dbname: gatherer
      username: gatherer
      port: 5432
```