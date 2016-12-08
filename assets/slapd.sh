#!/bin/bash

set -e

# check if the data directory is empty
if [[ ! -d /data/openldap/db ]]; then
        # this is the first time the container is starting up
        FIRST_RUN=1

        # create database directory
        mkdir /data/openldap/db

        # create config directory and copy current configuration
        mkdir /data/openldap/config
        cp -r /etc/openldap/slapd.d/* /data/openldap/config/
fi

if [[ ! -f /var/lib/ldap/DB_CONFIG ]]; then
  cp /usr/share/openldap-servers/DB_CONFIG.example /data/openldap/db/DB_CONFIG
fi

# create the link to the config directory
rm -rf /etc/openldap/slapd.d
ln -s /data/openldap/config /etc/openldap/slapd.d

if [[ ! -z "$MAX_NOFILE" ]]; then
  ulimit -n $MAX_NOFILE
fi

# start setup script in background
if [[ ! -z "$FIRST_RUN" ]]; then
        echo "running setup script"
        sh /opt/openldap/setup-slapd.sh > /opt/openldap/setup-slapd.log 2>&1 &
fi

# startup slapd in background
slapd -d 3000 -h "$LDAP_URL"

