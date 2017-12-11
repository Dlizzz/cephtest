#!/bin/bash
# ========================================================================================
# Define parameters for creation of the cephtest vagrant cluster
#
# Written by    : Denis Lambolez
# Release       : 1.0
# Creation date : 04 December 2017
# Description   : Bash script
#                 This script has been designed and written on Ubuntu 16.04 plateform.
#                 It's expected to be sourced by other scripts
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

# Version
VERSION=cephtest-utils-1.0-120417

# Ceph user
CEPH_ADMIN_USER="ceph-admin"
CEPH_ADMIN_EXEC="sudo -i -u $CEPH_ADMIN_USER"

# Machines
ADMIN_NODE="node-admin"
OSD_NODES="node-osd1 node-osd2"
NODES="$ADMIN_NODE $OSD_NODES"

# Networks
CLUSTER_NETWORK="172.28.128.0"

