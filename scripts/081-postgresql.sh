#!/usr/bin/env bash
set -eux

POSTGRESQL_VERSION=${POSTGRESQL_VERSION:-14}

apt-get install -y postgresql-${POSTGRESQL_VERSION}
