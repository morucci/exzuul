#!/bin/sh

set -x
set -e

# Git config complains about HOME env var missing ...
export HOME=/root

ADMINUSER=admin
ADMINUSEREMAIL=admin@ci.localdomain
CLONETEMPDIR="/tmp/All-projects"

[ -d "$CLONETEMPDIR" ] && rm -Rf $CLONETEMPDIR
git init $CLONETEMPDIR
cd $CLONETEMPDIR
git config --global user.name "SF initial configurator"
git config --global user.email $ADMINUSEREMAIL
git remote add origin ssh://$ADMINUSER@localhost:29418/All-Projects
GIT_SSH=/tmp/ssh_wrapper.sh git fetch origin refs/meta/config:refs/remotes/origin/meta/config
git checkout meta/config
cp /tmp/project.config .
git add project.config
git commit -a -m"Provide the default config" || true
GIT_SSH=/tmp/ssh_wrapper.sh git push origin meta/config:meta/config
cd -

egrep "\[localhost" /root/.ssh/known_hosts | sed 's/localhost/ci.localdomain/' >> /root/.ssh/known_hosts
