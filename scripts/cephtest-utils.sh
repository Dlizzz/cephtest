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

# Cluster name
CLUSTER_NAME="cephtest"

# Script name
SCRIPT=$(basename --suffix=.sh "$0")

# Define log output
OUTPUT_LOG="echo -e \n{$CLUSTER_NAME} {$SCRIPT} "

# Ceph user
CEPH_ADMIN_USER="ceph-admin"

# Nodes
ADMIN_NODE="node-admin"
OSD_NODES="node-osd1 node-osd2"
NODES="$ADMIN_NODE $OSD_NODES"

# Networks
CLUSTER_NETWORK="172.28.128.0/24"

# Guest name
GUEST_NAME=$(hostname -s)

# Guest directories
GUEST_USER_DIR="/home/$CEPH_ADMIN_USER"
GUEST_USER_SSH_DIR="$GUEST_USER_DIR/.ssh"
GUEST_VAGRANT_DIR="/vagrant"
GUEST_VAGRANT_SCRIPT_DIR="$GUEST_VAGRANT_DIR/scripts"
GUEST_VAGRANT_SSH_DIR="$GUEST_VAGRANT_DIR/.ssh"
GUEST_VAGRANT_SIGNAL_DIR="$GUEST_VAGRANT_DIR/.signals"

# Host directories
HOST_SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
HOST_SSH_DIR="$(readlink -f "$HOST_SCRIPT_DIR/../.ssh")"
HOST_SIGNAL_DIR="$(readlink -f "$HOST_SCRIPT_DIR/../.signals")"
