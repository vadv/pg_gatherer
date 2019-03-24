#!/bin/sh -ex
docker build -t gatherer:latest -f Dockerfile.example .
docker run --rm -t -v $(pwd):/app -i gatherer bash
