#!/bin/bash
# ========================================================================================
# Execute pre-up configuration needed to deploy vagrant cluster
#
# Written by    : Denis Lambolez
# Release       : 2.0
# Creation date : 16 December 2017
# Description   : Bash script
#                 This script has been designed and written on Ubuntu 16.04 plateform.
#                 It must be executed in vagrant context
# Usage         : ./pre-up.sh 
# ----------------------------------------------------------------------------------------
# ========================================================================================
#
# HISTORY :
#     Release   |     Date      |    Authors     |       Description
# --------------+---------------+--------------- +------------------------------------------
#       2.0     |    12.16.17   | Denis Lambolez | Renamed pre-up.sh and linked to post-destroy
#       1.1     |    12.04.17   | Denis Lambolez | Sourcing parameters from cephtest-utils
#       1.0     |    12.02.17   | Denis Lambolez | Creation
#               |               |                | 
# =========================================================================================
#set -xev

# Version
VERSION=pre-up-2.0-121617

# This script is executed in host context
source "$(dirname "$(readlink -f "$0")")/cephtest-utils.sh"

# (re)Create ssh keys
$OUTPUT_LOG "Create SSH keys and config for ceph admin user"
rm -f "$HOST_SSH_DIR/$CEPH_ADMIN_USER"-id_rsa*
ssh-keygen -q -N "" -f "$HOST_SSH_DIR/$CEPH_ADMIN_USER-id_rsa"
chmod 644 "$HOST_SSH_DIR/$CEPH_ADMIN_USER-id_rsa"
chmod 644 "$HOST_SSH_DIR/$CEPH_ADMIN_USER-id_rsa.pub"

# (re)Create ssh config file
rm -f "$HOST_SSH_DIR/$CEPH_ADMIN_USER-config"
for NODE in $NODES; do
    echo -e "Host $NODE\n\tHostname $NODE\n\tUser $CEPH_ADMIN_USER\n\tStrictHostKeyChecking no\n" | tee -a "$HOST_SSH_DIR/$CEPH_ADMIN_USER-config"
done
chmod 644 "$HOST_SSH_DIR/$CEPH_ADMIN_USER-config"

# Clean up IP and PROVISION signals
$OUTPUT_LOG "Clean up IP and PROVISION signals"
for NODE in $NODES; do
    rm -f "$HOST_SIGNAL_DIR/$NODE-IP"
    rm -f "$HOST_SIGNAL_DIR/$NODE-PROVISION"
done
