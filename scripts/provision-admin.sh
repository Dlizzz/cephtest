#!/bin/bash
# ========================================================================================
# Launch ceph installtion when cluster provisioning is done
#
# Written by    : Denis Lambolez
# Release       : 1.0
# Creation date : 18 December 2017
# Description   : Bash script
#                 This script has been designed and written on Ubuntu 16.04 plateform.
#                 It must be executed in vagrant context, on admin node 
# Usage         : ./provision-admin.sh
# ----------------------------------------------------------------------------------------
# ========================================================================================
#
# HISTORY :
#     Release   |     Date      |    Authors     |       Description
# --------------+---------------+--------------- +------------------------------------------
#       1.0     |    12.18.17   | Denis Lambolez | Creation
#               |               |                | 
#               |               |                | 
# =========================================================================================
#set -xv

# Version
VERSION=provision-admin-1.0-121817

# This script is executed in guest context
source "/vagrant/scripts/cephtest-utils.sh"

# Make sure this script is run from the admin node
if [[ $(hostname -s) != $ADMIN_NODE ]]; then
   echo "This script must be run from $ADMIN_NODE" 1>&2
   exit 1
fi

# Wait for all nodes to be ready
TIMER_MAX=300
for NODE in $NODES; do
    TIMER=0
    until [[ -r "$GUEST_VAGRANT_SIGNAL_DIR/$NODE-PROVISION" ]]; do
        sleep 1
        TIMER=$(($TIMER + 1))
        if [[ $TIMER -gt $TIMER_MAX ]]; then
            echo "Waited too long for $NODE!" >&2
            exit 1
        fi
    done
done

# Launch ceph-installation
sudo -i -u $CEPH_ADMIN_USER $GUEST_VAGRANT_SCRIPT_DIR/ceph-install.sh