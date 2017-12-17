#!/bin/bash
# ========================================================================================
# Execute ceph distributed storage installation steps from the admin node via ceph-deploy
#
# Written by    : Denis Lambolez
# Release       : 1.0
# Creation date : 04 December 2017
# Description   : Bash script
#                 This script has been designed and written on Ubuntu 16.04 plateform.
#                 It must be executed in ceph-admin context, on admin node 
# Usage         : ./ceph-install.sh
# ----------------------------------------------------------------------------------------
# ========================================================================================
#
# HISTORY :
#     Release   |     Date      |    Authors     |       Description
# --------------+---------------+--------------- +------------------------------------------
#       1.0     |    12.04.17   | Denis Lambolez | Creation
#               |               |                | 
#               |               |                | 
#               |               |                | 
# =========================================================================================
#set -xv

# Version
VERSION=ceph-install-1.0-120417

# This script is executed in guest context
source "/vagrant/scripts/cephtest-utils.sh"

# Network (dynamically defined by Vagrant)
IP_ADDRESS=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
PUBLIC_NETWORK=$(echo $IP_ADDRESS | awk -F '.' '{print $1"."$2"."$3".0"}')

# Make sure only CEPH_ADMIN_USER can run the script
if [[ $(whoami) != $CEPH_ADMIN_USER ]]; then
   echo "This script must be run as $CEPH_ADMIN_USER" 1>&2
   exit 1
fi

# Make sure this script is run from the admin node
if [[ $(hostname -s) != $ADMIN_NODE ]]; then
   echo "This script must be run from $ADMIN_NODE" 1>&2
   exit 1
fi

# Cluster configuration directory
mkdir -p "$GUEST_USER_DIR/ceph-cluster"
cd "$GUEST_USER_DIR/ceph-cluster"

# Initialize cluster configuration
ceph-deploy new node-admin
echo "public network = $PUBLIC_NETWORK" >> ceph.conf
echo "cluster network = $CLUSTER_NETWORK" >> ceph.conf
echo "" >> ceph.conf
echo "osd pool default size = 2" >> ceph.conf
echo "osd pool default min size = 1" >> ceph.conf

# Install ceph on all nodes
ceph-deploy install --release luminous node-admin node-osd1 node-osd2