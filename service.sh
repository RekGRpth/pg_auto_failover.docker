#!/bin/sh -x

docker pull rekgrpth/pg_auto_failover || exit $?
docker volume create monitor || echo $?
docker volume create postgres || echo $?
docker network create --attachable --driver overlay docker || echo $?
docker service rm postgres-1 || echo $?
docker service rm postgres-2 || echo $?
docker service rm monitor || echo $?
docker service create \
    --constraint node.role==manager \
    --hostname tasks.monitor \
    --mount type=volume,source=monitor,destination=/home \
    --name monitor \
    --network name=docker \
    --replicas-max-per-node 1 \
    rekgrpth/pg_auto_failover sh -cx "chown -R postgres:postgres /home && su-exec postgres pg_autoctl -vvv create monitor --nodename tasks.monitor --no-ssl --auth trust && su-exec postgres pg_autoctl -vvv run"
docker service create \
    --constraint node.labels.host==docker-1 \
    --hostname tasks.postgres-1 \
    --mount type=volume,source=postgres,destination=/home \
    --name postgres-1 \
    --network name=docker \
    --replicas-max-per-node 1 \
    rekgrpth/pg_auto_failover sh -cx "chown -R postgres:postgres /home && su-exec postgres pg_autoctl -vvv create postgres --nodename tasks.postgres-1 --no-ssl --auth trust --monitor=postgres://autoctl_node@tasks.monitor:5432/pg_auto_failover && su-exec postgres pg_autoctl -vvv run"
docker service create \
    --constraint node.labels.host==docker-2 \
    --hostname tasks.postgres-2 \
    --mount type=volume,source=postgres,destination=/home \
    --name postgres-2 \
    --network name=docker \
    --replicas-max-per-node 1 \
    rekgrpth/pg_auto_failover sh -cx "chown -R postgres:postgres /home && su-exec postgres pg_autoctl -vvv create postgres --nodename tasks.postgres-2 --no-ssl --auth trust --monitor=postgres://autoctl_node@tasks.monitor:5432/pg_auto_failover && su-exec postgres pg_autoctl -vvv run"
