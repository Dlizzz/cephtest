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
set -xv

# Version
VERSION=ceph-install-1.0-120417

# This script is executed in guest context
source "/vagrant/scripts/cephtest-utils.sh"
# Directories (depending of the context)
GUEST_USER_DIR="/home/$CEPH_ADMIN_USER"
GUEST_USER_SSH_DIR="$GUEST_USER_DIR/.ssh"
GUEST_VAGRANT_SCRIPT_DIR="/vagrant/scripts"
GUEST_VAGRANT_SSH_DIR="/vagrant/.ssh"

GUEST_IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
PUBLIC_NETWORK=$(echo $GUEST_IP | awk -F '.' '{print $1"."$2"."$3".0/24"}')

mkdir -p "$GUEST_USER_DIR/ceph-cluster"
cd "$GUEST_USER_DIR/ceph-cluster"
#ceph-deploy new node-admin
#echo "public network = $PUBLIC_NETWORK" >> ceph.conf
#echo "cluster network = $CLUSTER_NETWORK" >> ceph.conf
#echo "" >> ceph.conf
#echo "osd pool default size = 2" >> ceph.conf
#echo "osd pool default min size = 1" >> ceph.conf