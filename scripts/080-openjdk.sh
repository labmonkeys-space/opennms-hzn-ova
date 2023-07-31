#!/usr/bin/env bash
set -eux

OPENJDK_VERSION="${OPENJDK_VERSION:-17}"
apt-get install -y "openjdk-${OPENJDK_VERSION}-jdk"
echo "export JAVA_HOME=\"/usr/lib/jvm/java-${OPENJDK_VERSION}-openjdk-amd64\"" >> /etc/profile.d/080-javahome.sh
