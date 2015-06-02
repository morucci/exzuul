#!/bin/bash

/usr/libexec/postfix/aliasesdb
postfix start
tailf /var/log/maillog
