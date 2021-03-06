#!/bin/sh -ex

#docker build --tag rekgrpth/pg_auto_failover .
#docker push rekgrpth/pg_auto_failover
#docker pull rekgrpth/pg_auto_failover || exit $?
docker network create --attachable --driver overlay docker1 || echo $?
docker volume create monitor || echo $?
docker service rm monitor || echo $?
docker service create \
    --env CLUSTER_NAME=monitor \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env PG_AUTOCTL_SERVER_CERT=/etc/certs/cert.pem \
    --env PG_AUTOCTL_SERVER_KEY=/etc/certs/key.pem \
    --env PG_AUTOCTL_SSL_CA_FILE=/etc/certs/ca.pem \
    --env PG_AUTOCTL_SSL_MODE=prefer \
    --env PG_AUTOCTL=true \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname tasks.monitor \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=monitor,destination=/var/lib/postgresql \
    --name monitor \
    --network name=docker1 \
    rekgrpth/pg_auto_failover runsvdir /etc/service
docker volume create keeper || echo $?
for I in 1 2 3 4; do
docker service rm "keeper$I" || echo $?
docker service create \
    --env CLUSTER_NAME=test \
    --env GROUP_ID="$(id -g)" \
    --env LANG=ru_RU.UTF-8 \
    --env PG_AUTOCTL_MONITOR=postgres://autoctl_node@tasks.monitor/pg_auto_failover?sslmode=prefer \
    --env PG_AUTOCTL_NAME="keeper$I" \
    --env PG_AUTOCTL_REPLICATION_QUORUM=false \
    --env PG_AUTOCTL_SERVER_CERT=/etc/certs/cert.pem \
    --env PG_AUTOCTL_SERVER_KEY=/etc/certs/key.pem \
    --env PG_AUTOCTL_SSL_CA_FILE=/etc/certs/ca.pem \
    --env PG_AUTOCTL_SSL_MODE=prefer \
    --env PG_AUTOCTL=true \
    --env PGDATA="/var/lib/postgresql/pg_data.$I" \
    --env TZ=Asia/Yekaterinburg \
    --env USER_ID="$(id -u)" \
    --hostname="tasks.keeper$I" \
    --mount type=bind,source=/etc/certs,destination=/etc/certs,readonly \
    --mount type=volume,source=keeper,destination=/var/lib/postgresql \
    --name "keeper$I" \
    --network name=docker1 \
    rekgrpth/pg_auto_failover runsvdir /etc/service
done
