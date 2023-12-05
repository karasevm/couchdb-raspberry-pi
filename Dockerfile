FROM debian:bullseye as builder

ENV COUCHDB_VERSION 3.3.3
ENV NODEVERSION 16

# Prepare build env
RUN apt-get update && apt-get install -y git
RUN git clone --depth 1 https://github.com/apache/couchdb-ci.git
RUN bash /couchdb-ci/bin/install-dependencies.sh
RUN apt-get install -y --no-install-recommends pkg-kde-tools python libffi-dev 

# Build SpiderMonkey 1.8.5
RUN git clone --depth 1 https://github.com/apache/couchdb-pkg.git
WORKDIR /couchdb-pkg
RUN make couch-js-debs PLATFORM=$(lsb_release -cs)
RUN apt-get -y install /couchdb-pkg/js/couch-libmozjs185*.deb



# Build CouchDB
WORKDIR /
RUN git clone --depth 1 --branch $COUCHDB_VERSION https://github.com/apache/couchdb.git 
WORKDIR /couchdb
RUN ./configure --disable-docs
# workaround chromedriver not supporting armv7
RUN sed -i 's/npm install/npm uninstall chromedriver \&\& npm install/g' Makefile 
RUN make release

FROM debian:bullseye-slim

COPY --from=builder /couchdb/rel/couchdb /opt/couchdb
COPY --from=builder /couchdb-pkg/js/*.deb /tmp/debs/
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
    apt-get install -y /tmp/debs/*.deb; \
    apt-get install -y --no-install-recommends gosu tini erlang-nox erlang-reltool libicu67; \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /tmp/debs/*; \
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