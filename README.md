# Apache CouchDB Docker images for Raspberry Pi (armhf)
A drop-in replacement for the official CouchDB docker container with support for
older 32-bit Raspberry Pi boards.

Dockerfile is based on the [official one](https://github.com/apache/couchdb-docker)
so the documentation provided [here](https://github.com/apache/couchdb-docker/blob/master/README.md) should be compatible.

While the main reason for this project is armhf support, the images are also built
for amd64 and arm64 for docker compose portability.