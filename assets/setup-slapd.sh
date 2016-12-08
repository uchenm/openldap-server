#/bin/bash

set -e

# wait for slapd to be started up
sleep 5

# change database suffix of the root DN
if [[ -z "$LDAP_DOMAIN" ]]; then
        LDAP_DOMAIN=corexx.org
fi

LDAP_SUFFIX=$(sed -e 's/^/dc=/' -e 's/\./,dc=/g' <<< $LDAP_DOMAIN)
echo "change database suffix of the root DN to $LDAP_SUFFIX"
ldapmodify -H ldapi:/// <<EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: $LDAP_SUFFIX

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=root,$LDAP_SUFFIX
EOF

# set password of root DN
if [[ -z "$LDAP_PASSWORD" ]]; then
        LDAP_PASSWORD=password
fi

HASHED_PASSWORD=$(slappasswd -s $LDAP_PASSWORD)
echo "set password of root DN to $HASHED_PASSWORD"
ldapmodify -H ldapi:/// <<EOF
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $HASHED_PASSWORD
EOF

# adding default schema
echo "adding openldap schema cosine.ldif"
ldapadd -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
echo "adding openldap schema inetorgperson.ldif"
ldapadd -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

# add the ldap domain
echo "adding ldap domain cn=root,$LDAP_SUFFIX"
ldapadd -H ldapi:/// -x -w $LDAP_PASSWORD -D "cn=root,$LDAP_SUFFIX" <<EOF
dn: $LDAP_SUFFIX
objectClass: domain
dc: $(sed -e 's/,.*//' -e 's/dc=//' <<< $LDAP_SUFFIX)
EOF

# adding organization unit
echo "adding organization unit"
ldapadd -H ldapi:/// -x -w $LDAP_PASSWORD -D "cn=root,$LDAP_SUFFIX" <<EOF
dn: ou=people,$LDAP_SUFFIX
ou: people
description: All Users.
objectclass: top
objectClass: organizationalUnit
EOF

# adding groups branch
echo "adding groups branch"
ldapadd -H ldapi:/// -x -w $LDAP_PASSWORD -D "cn=root,$LDAP_SUFFIX" <<EOF
dn: ou=groups,$LDAP_SUFFIX
ou: groups
description: All Groups.
objectclass: top
objectClass: organizationalUnit
EOF

# adding services branch
echo "adding groups branch"
ldapadd -H ldapi:/// -x -w $LDAP_PASSWORD -D "cn=root,$LDAP_SUFFIX" <<EOF
dn: ou=services,$LDAP_SUFFIX
ou: services
description: All Services.
objectclass: top
objectClass: organizationalUnit
EOF

# install additional ldapmodify scripts if available
if [ -d "/data/openldap/ldapmodify/" ]
then
        for SCRIPT in `ls /data/openldap/ldapmodify/`
        do
                ldapmodify -Y EXTERNAL -H ldapi:/// -f /data/openldap/ldapmodify/$SCRIPT
        done
fi

# install additional ldapadd scripts if available
if [ -d "/data/openldap/ldapadd/" ]
then
        for SCRIPT in `ls /data/openldap/ldapadd/`
        do
                ldapadd -H ldapi:/// -x -w $LDAP_PASSWORD -D "cn=root,$LDAP_SUFFIX" -f /data/openldap/ldapadd/$SCRIPT
        done
fi

