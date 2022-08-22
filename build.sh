#!/usr/bin/env bash

IMAGE_NAME=karasevm/couchdb-raspberry-pi
COUCHDB_VERSION=3.2.2
COUCHDB_VERSION_MAJOR=3
output='docker'
platform='linux/amd64,linux/arm64,linux/arm/v7'

while getopts 'o:p:' flag; do
  case "${flag}" in
    o) output="${OPTARG}" ;;
    p) platform="${OPTARG}" ;;
  esac
done



docker buildx create --use
docker buildx build \
  --platform=$platform \
  --build-arg COUCHDB_VERSION=$COUCHDB_VERSION \
  -t $IMAGE_NAME:latest -t $IMAGE_NAME:$COUCHDB_VERSION -t $IMAGE_NAME:$COUCHDB_VERSION_MAJOR \
  -o type=$output \
  .
