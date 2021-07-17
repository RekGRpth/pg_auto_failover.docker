#!/bin/sh -eux

DOCKER_BUILDKIT=1 docker build --progress=plain --tag rekgrpth/pg_auto_failover . 2>&1 | tee build.log
