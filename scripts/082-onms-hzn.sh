#!/usr/bin/env bash
set -eux

ONMS_GPG_KEYRING="/usr/share/keyrings/opennms-keyring.gpg"
ONMS_MIRROR="${ONMS_MIRROR:-debian.opennms.org}"
ONMS_RELEASE="${ONMS_RELEASE:-stable}"
ONMS_JRRD2_VERSION="${ONMS_JRRD2_VERSION:-*}"
ONMS_HZN_VERSION="${ONMS_HZN_VERSION:-*}"
OPENNMS_HOME="/usr/share/opennms"

POSTGRES_PASS="pgadminP455"
DB_NAME="opennms_hzn"
DB_USER="opennms"
DB_PASS="onmsP455"

echo "export OPENNMS_HOME=\"/usr/share/opennms\"" >> /etc/profile.d/082-onmshome.sh

# Initialize PostgreSQL database
sudo -i -u postgres psql -c "ALTER SYSTEM SET password_encryption = 'scram-sha-256';"
systemctl restart postgresql
sudo -i -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASS}';"
sudo -i -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"
sudo -i -u postgres psql -c "GRANT CREATE ON SCHEMA public TO PUBLIC;"
sudo -i -u postgres psql -c "CREATE DATABASE ${DB_NAME} WITH OWNER ${DB_USER};"

# Install the OpenNMS Horizon repository and the GPG signing key
curl -fsSL https://debian.opennms.org/OPENNMS-GPG-KEY | sudo gpg --dearmor -o "${ONMS_GPG_KEYRING}"
printf 'deb [signed-by=%s] https://%s %s main\n' "${ONMS_GPG_KEYRING}" "${ONMS_MIRROR}" "${ONMS_RELEASE}" \
  | tee /etc/apt/sources.list.d/opennms.list
apt-get update

#  Install some tools to improve functionality using RRDTool
apt-get install -y haveged rrdtool

# Install OpenNMS packages
apt-get install --no-install-recommends -y jrrd2="${ONMS_JRRD2_VERSION}" opennms="${ONMS_HZN_VERSION}"

# Setup secure vault for storing credentials encrypted
sudo -u opennms "${OPENNMS_HOME}"/bin/scvcli set postgres "${DB_USER}" "${DB_PASS}"
sudo -u opennms "${OPENNMS_HOME}"/bin/scvcli set postgres-admin "postgres" "${POSTGRES_PASS}"

printf '<?xml version="1.0" encoding="UTF-8"?>
<datasource-configuration>
  <connection-pool factory="org.opennms.core.db.C3P0ConnectionFactory"
    idleTimeout="600"
    loginTimeout="3"
    minPool="50"
    maxPool="50"
    maxSize="50" />

  <jdbc-data-source name="opennms"
                    database-name="%s"
                    class-name="org.postgresql.Driver"
                    url="jdbc:postgresql://localhost:5432/%s"
                    user-name="${scv:postgres:username}"
                    password="${scv:postgres:password}" />

  <jdbc-data-source name="opennms-admin"
                    database-name="template1"
                    class-name="org.postgresql.Driver"
                    url="jdbc:postgresql://localhost:5432/template1"
                    user-name="${scv:postgres-admin:username}"
                    password="${scv:postgres-admin:password}" />
</datasource-configuration>' "${DB_NAME}" "${DB_NAME}" \
  | sudo -u opennms tee "${OPENNMS_HOME}"/etc/opennms-datasources.xml

printf 'org.opennms.rrd.strategyClass=org.opennms.netmgt.rrd.rrdtool.MultithreadedJniRrdStrategy
org.opennms.rrd.interfaceJar=/usr/share/java/jrrd2.jar
opennms.library.jrrd2=/usr/lib/jni/libjrrd2.so
org.opennms.web.graphs.engine=rrdtool
rrd.binary=/usr/bin/rrdtool\n' | sudo -u opennms tee "${OPENNMS_HOME}"/etc/opennms.properties.d/rrdtool-backend.properties

# Workaround for Invalid CEN header (invalid zip64 extra data field size)
# See: https://opennms.atlassian.net/browse/NMS-16034
echo "ADDITIONAL_MANAGER_OPTIONS=-Djdk.util.zip.disableZip64ExtraFieldValidation=true" | sudo -u opennms tee -a /etc/opennms/opennms.conf

sudo -u opennms "${OPENNMS_HOME}"/bin/runjava -s
sudo -u opennms "${OPENNMS_HOME}"/bin/install -dis

# Enable service on startup
systemctl enable opennms
