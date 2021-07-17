FROM alpine
ENV HOME=/var/lib/postgresql
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        gcc \
        git \
        libedit-dev \
        libxml2-dev \
        make \
        musl-dev \
        postgresql-dev \
        readline-dev \
        zlib-dev \
    ; \
    mkdir -p "${HOME}/src"; \
    cd "${HOME}/src"; \
    git clone --recursive https://github.com/RekGRpth/pg_auto_failover.git; \
    git clone --recursive https://github.com/RekGRpth/pg_rman.git; \
    git clone --recursive https://github.com/RekGRpth/pgsidekick.git; \
    cd "${HOME}/src/pg_auto_failover"; \
    make -j"$(nproc)" USE_PGXS=1 install; \
    cd "${HOME}/src/pg_rman"; \
    git checkout REL_13_STABLE; \
    make -j"$(nproc)" USE_PGXS=1 install; \
    cd "${HOME}/src/pgsidekick"; \
    make -j"$(nproc)" pglisten; \
    cp -f pglisten /usr/local/bin/; \
    cp -f /usr/bin/pg_config /usr/local/bin/; \
    cd "${HOME}"; \
    apk add --no-cache --virtual .postgresql-rundeps \
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
        $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local | tr ',' '\n' | sort -u | while read -r lib; do test ! -e "/usr/local/lib/$lib" && echo "so:$lib"; done) \
    ; \
    find /usr/local/bin -type f -exec strip '{}' \;; \
    find /usr/local/lib /usr/lib/postgresql -type f -name "*.so" -exec strip '{}' \;; \
    apk del --no-cache .build-deps; \
    mv -f /usr/local/bin/pg_config /usr/bin/; \
    find / -type f -name "*.a" -delete; \
    find / -type f -name "*.la" -delete; \
    rm -rf "${HOME}" /usr/share/doc /usr/share/man /usr/local/share/doc /usr/local/share/man; \
    echo done
ADD bin /usr/local/bin
ADD service /etc/service
CMD [ "/etc/service/postgres/run" ]
ENTRYPOINT [ "docker_entrypoint.sh" ]
ENV BACKUP_PATH="${HOME}/pg_rman" \
    GROUP=postgres \
    PGDATA="${HOME}/pg_data" \
    USER=postgres
VOLUME "${HOME}"
WORKDIR "${HOME}"
RUN set -eux; \
    chmod -R 0755 /etc/service /usr/local/bin; \
    rm -f /var/spool/cron/crontabs/root; \
    echo done
