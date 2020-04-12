FROM alpine
CMD [ "sh" ]
ENTRYPOINT [ "su-exec", "postgres" ]
ENV HOME=/var/lib/postgresql
ENV PGDATA="${HOME}/pg_data"
WORKDIR "${HOME}"
VOLUME "${HOME}"
RUN set -x \
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
    && cd /usr/src/pg_auto_failover \
    && make -j"$(nproc)" USE_PGXS=1 install \
    && apk add --no-cache --virtual .postgresql-rundeps \
        postgresql \
        su-exec \
        $(scanelf --needed --nobanner --format '%n#p' --recursive /usr/lib/postgresql/pgautofailover.so | tr ',' '\n' | sort -u | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }') \
    && apk del --no-cache .build-deps \
    && rm -rf /usr/src \
    && mkdir -p /run/postgresql \
    && chown -R postgres:postgres "${HOME}" /run/postgresql
