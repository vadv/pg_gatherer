#!/usr/bin/env bash

# start pg
sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/initdb -D /tmp/db'
sudo -H -u postgres bash -l -c '/usr/pgsql-11/bin/pg_ctl start -W -D /tmp/db'
sleep 3

# prepare database gatherer
psql -U postgres -Atc "create user gatherer"
psql -U postgres -Atc "create database gatherer owner gatherer"

psql -U gatherer -At -1 -f ./schema/schema.sql -d gatherer