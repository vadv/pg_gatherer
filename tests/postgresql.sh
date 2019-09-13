#!/usr/bin/env bash

# start pg
sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/initdb -D /tmp/db'
sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/pg_ctl start -W -D /tmp/db'
sleep 3

# prepare database coinsph
psql -U postgres -Atc "create user coinsph"
psql -U postgres -Atc "create database coinsph owner coinsph"

psql -U coinsph -At -1 -f ./schema/schema.sql -d coinsph