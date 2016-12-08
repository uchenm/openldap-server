FROM centos:7

MAINTAINER Ming Chen <ming.chen@163.com>

# install OpenLDAP Server
RUN yum -y install openldap-servers openldap-clients && \
    yum clean all

# define slapd url
env LDAP_URL ldapi:/// ldap:/// ldaps:///

# add startup script
ADD assets/slapd.sh /opt/openldap/slapd.sh
ADD assets/setup-slapd.sh /opt/openldap/setup-slapd.sh

# populate database
RUN mkdir -p /data/openldap && \
    rmdir /var/lib/ldap && \
    ln -s /data/openldap/db/ /var/lib/ldap

# define volumes
VOLUME /data/openldap

# expose ports
EXPOSE 389 636

# start Teamspeak Server
CMD ["sh", "/opt/openldap/slapd.sh"]
