#!/bin/sh
ssh -o StrictHostKeyChecking=no -i /var/lib/keys/id_rsa "$@"
