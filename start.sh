#!/bin/bash

set -x

export JAVA_HOME=/usr/lib/jvm/java-1.6.0-openjdk-1.6.0.34.x86_64/jre/

/usr/bin/java -jar /opt/gerrit/site_path/gerrit.war init -d /opt/gerrit/site_path --batch --no-auto-start

# Init admin user
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNTS values (NULL, 'admin', NULL, NULL, 'N', NULL, NULL, NULL, NULL, 25, 'N', 'N', 'Y', 'N', NULL, 'Y', 'N', 'admin@ci.localdomain', '2015-05-28 11:00:30.001', 1)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_GROUP_MEMBERS values (1, 1)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_EXTERNAL_IDS values (1, 'admin@ci.localdomain', NULL, 'username:admin')"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_EXTERNAL_IDS values (1, 'admin@ci.localdomain', NULL, 'mailto:admin@ci.localdomain')"

# Init zuul user
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNTS values (NULL, 'zuul', NULL, NULL, 'N', NULL, NULL, NULL, NULL, 25, 'N', 'N', 'Y', 'N', NULL, 'Y', 'N', 'zuul@ci.localdomain', '2015-05-28 11:00:30.001', 2)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_GROUP_MEMBERS values (2, 4)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_EXTERNAL_IDS values (2, 'zuul@ci.localdomain', NULL, 'username:zuul')"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into ACCOUNT_EXTERNAL_IDS values (2, 'zuul@ci.localdomain', NULL, 'mailto:zuul@ci.localdomain')"

mkdir /var/lib/keys
ssh-keygen -N '' -f /var/lib/keys/id_rsa

pubkey=$(cat /var/lib/keys/id_rsa.pub)
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into account_ssh_keys values ('$pubkey', 'Y', 2, 1)"
java -jar /opt/gerrit/site_path/gerrit.war gsql -d /opt/gerrit/site_path/ -c "insert into account_ssh_keys values ('$pubkey', 'Y', 1, 1)"

# Post actions after gerrit start - this is a quick and dirty solution
bash -c "sleep 20; /tmp/gerrit-post.sh" &

supervisord -n
