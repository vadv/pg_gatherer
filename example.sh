#!/bin/sh -ex
pushd `dirname "$(readlink -f "$0")"`
docker build -t pg_gatherer:latest -f Dockerfile.example .
docker run --rm -t -v $(pwd):/app -i pg_gatherer bash
