#!/bin/bash
# ========================================================================================
# Execute post-destroy cleaning
#
# Written by    : Denis Lambolez
# Release       : 1.0
# Creation date : 16 December 2017
# Description   : Bash script
#                 This script has been designed and written on Ubuntu 16.04 plateform.
#                 It must be executed in vagrant context
# Usage         : ./post-destroy.sh 
# ----------------------------------------------------------------------------------------
# ========================================================================================
#
# HISTORY :
#     Release   |     Date      |    Authors     |       Description
# --------------+---------------+--------------- +------------------------------------------
#       1.0     |    12.16.17   | Denis Lambolez | Creation
#               |               |                | 
# =========================================================================================
#set -xev

# Version
VERSION=post-destroy-1.0-121617

# This script is executed in host context
source "$(dirname "$(readlink -f "$0")")/cephtest-utils.sh"

# clean-up networks to start with fresh configuration
for NETWORK in vagrant-libvirt vagrant-private-dhcp; do
    virsh net-list --all 2> /dev/null | grep $NETWORK | grep active
    if [[ $? -eq 0 ]]; then
        virsh net-destroy $NETWORK  2> /dev/null
    fi
    virsh net-list --all  2> /dev/null | grep $NETWORK
    if [[ $? -eq 0 ]]; then
        virsh net-undefine $NETWORK  2> /dev/null
    fi
done
