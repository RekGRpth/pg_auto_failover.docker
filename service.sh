#!/bin/sh -x

docker pull rekgrpth/pg_auto_failover || exit $?
docker volume create monitor || echo $?
docker volume create postgres || echo $?
docker network create --attachable --driver overlay docker || echo $?
docker service rm postgres1 || echo $?
docker service rm postgres2 || echo $?
docker service rm monitor || echo $?
docker service create \
    --constraint node.role==manager \
    --hostname tasks.monitor \
    --mount type=volume,source=monitor,destination=/var/lib/postgresql \
    --name monitor \
    --network name=docker \
    --replicas-max-per-node 1 \
    rekgrpth/pg_auto_failover sh -cx "pg_autoctl -vvv create monitor --nodename tasks.monitor --no-ssl --auth trust; pg_autoctl -vvv run"
docker service create \
    --constraint node.hostname==docker1 \
    --hostname tasks.postgres1 \
    --mount type=volume,source=postgres,destination=/var/lib/postgresql \
    --name postgres1 \
    --network name=docker \
    --replicas-max-per-node 1 \
    rekgrpth/pg_auto_failover sh -cx "pg_autoctl -vvv create postgres --nodename tasks.postgres1 --no-ssl --auth trust --allow-removing-pgdata --monitor=postgres://autoctl_node@tasks.monitor:5432/pg_auto_failover; pg_autoctl -vvv run"
docker service create \
    --constraint node.hostname==docker2 \
    --hostname tasks.postgres2 \
    --mount type=volume,source=postgres,destination=/var/lib/postgresql \
    --name postgres2 \
    --network name=docker \
    --replicas-max-per-node 1 \
    rekgrpth/pg_auto_failover sh -cx "pg_autoctl -vvv create postgres --nodename tasks.postgres2 --no-ssl --auth trust --allow-removing-pgdata --monitor=postgres://autoctl_node@tasks.monitor:5432/pg_auto_failover; pg_autoctl -vvv run"
