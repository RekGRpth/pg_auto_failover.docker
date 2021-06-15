FROM alpine
RUN exec 2>&1 \
    && set -ex \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        git \
        libedit-dev \
        libxml2-dev \
        make \
        musl-dev \
        postgresql-dev \
        zlib-dev \
    && mkdir -p /usr/src \
    && cd /usr/src \
    && git clone --recursive https://github.com/RekGRpth/pg_auto_failover.git \
    && git clone --recursive https://github.com/RekGRpth/pg_rman.git \
    && git clone --recursive https://github.com/RekGRpth/pgsidekick.git \
    && cd /usr/src/pg_auto_failover \
    && make -j"$(nproc)" USE_PGXS=1 install \
    && cd /usr/src/pg_rman \
    && git checkout REL_13_STABLE \
    && make -j"$(nproc)" USE_PGXS=1 install \
    && cd /usr/src/pgsidekick \
    && make -j"$(nproc)" pglisten \
    && cp -f pglisten /usr/local/bin/ \
    && cp -f /usr/bin/pg_config /usr/local/bin/ \
    && apk add --no-cache --virtual .postgresql-rundeps \
        busybox-extras \
        busybox-suid \
        ca-certificates \
        jq \
        musl-locales \
        pgbouncer \
        postgresql \
        postgresql-contrib \
        procps \
        runit \
        sed \
        shadow \
        tzdata \
        $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/lib/postgresql/pgautofailover.so | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }') \
    && apk del --no-cache .build-deps \
    && mv -f /usr/local/bin/pg_config /usr/bin/ \
    && rm -rf /usr/src /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man \
    && echo done
ADD bin /usr/local/bin
ADD service /etc/service
CMD [ "/etc/service/postgres/run" ]
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV HOME=/var/lib/postgresql
ENV BACKUP_PATH=${HOME}/pg_rman \
    GROUP=postgres \
    PGDATA="${HOME}/pg_data" \
    USER=postgres
VOLUME "${HOME}"
WORKDIR "${HOME}"
RUN exec 2>&1 \
    && set -ex \
    && chmod -R 0755 /etc/service /usr/local/bin \
    && rm -f /var/spool/cron/crontabs/root \
    && echo done
