#!/bin/bash
# ========================================================================================
# Execute preflight configuration needed to deploy vagrant cluster
#
# Written by    : Denis Lambolez
# Release       : 1.1
# Creation date : 04 December 2017
# Description   : Bash script
#                 This script has been designed and written on Ubuntu 16.04 plateform.
#                 It must be executed in vagrant context
# Usage         : ./vagrant-preflight.sh 
# ----------------------------------------------------------------------------------------
# ========================================================================================
#
# HISTORY :
#     Release   |     Date      |    Authors     |       Description
# --------------+---------------+--------------- +------------------------------------------
#       1.1     |    12.04.17   | Denis Lambolez | Sourcing parameters from cephtest-utils
#       1.0     |    12.02.17   | Denis Lambolez | Creation
#               |               |                | 
#               |               |                | 
# =========================================================================================
#set -xev

# Version
VERSION=vagrant-preflight-1.0-120217

# This script is executed in host context
source "$(dirname "$(readlink -f "$0")")/cephtest-utils.sh"
# Directories (depending of the context)
HOST_SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
HOST_SSH_DIR="$(readlink -f "$HOST_SCRIPT_DIR/../.ssh")"

# (re)Create ssh keys
rm -f "$HOST_SSH_DIR/$CEPH_ADMIN_USER"-id_rsa*
ssh-keygen -q -N "" -f "$HOST_SSH_DIR/$CEPH_ADMIN_USER-id_rsa"
chmod 644 "$HOST_SSH_DIR/$CEPH_ADMIN_USER-id_rsa"
chmod 644 "$HOST_SSH_DIR/$CEPH_ADMIN_USER-id_rsa.pub"

# (re)Create ssh config file
rm -f "$HOST_SSH_DIR/$CEPH_ADMIN_USER-config"
for NODE in $NODES; do
    echo -e "Host $NODE\n\tHostname $NODE\n\tUser $CEPH_ADMIN_USER\n\tStrictHostKeyChecking no\n" >> "$HOST_SSH_DIR/$CEPH_ADMIN_USER-config"
done
chmod 644 "$HOST_SSH_DIR/$CEPH_ADMIN_USER-config"
