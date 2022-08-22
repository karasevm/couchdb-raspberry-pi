FROM debian:bullseye as builder

ENV COUCHDB_VERSION 3.2.2

# Prepare build env
RUN apt-get update
RUN apt-get install -y git pkg-kde-tools python libffi-dev
RUN git clone https://github.com/apache/couchdb-ci.git
RUN bash couchdb-ci/bin/install-dependencies.sh

# Build CouchDB
RUN git clone --depth 1 --branch $COUCHDB_VERSION https://github.com/apache/couchdb.git 
WORKDIR /couchdb
RUN ./configure --disable-docs --spidermonkey-version 78
RUN make release

FROM debian:bullseye-slim

COPY --from=builder /couchdb/rel/couchdb /opt/couchdb
COPY --chown=couchdb:couchdb 10-docker-default.ini /opt/couchdb/etc/default.d/
COPY --chown=couchdb:couchdb vm.args /opt/couchdb/etc/
COPY docker-entrypoint.sh /usr/local/bin

RUN groupadd -g 5984 -r couchdb && useradd -u 5984 -d /opt/couchdb -g couchdb couchdb; \
    chown -R couchdb:couchdb /opt/couchdb; \
    find /opt/couchdb -type d -exec chmod 0770 {}; \
    chmod 0644 /opt/couchdb/etc/*; \
    chmod +x /usr/local/bin/docker-entrypoint.sh

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends gosu tini erlang-nox erlang-reltool libicu67 libmozjs-78-0; \
    rm -rf /var/lib/apt/lists/*; \
    gosu nobody true; \
    tini --version

RUN ln -s usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh # backwards compat
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]

VOLUME /opt/couchdb/data

# 5984: Main CouchDB endpoint
# 4369: Erlang portmap daemon (epmd)
# 9100: CouchDB cluster communication port
EXPOSE 5984 4369 9100
CMD ["/opt/couchdb/bin/couchdb"]