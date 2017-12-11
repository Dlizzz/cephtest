#!/bin/bash
# ========================================================================================
# Execute preflight configuration needed to deploy ceph distributed storage
#
# Written by    : Denis Lambolez
# Release       : 1.1
# Creation date : 04 December 2017
# Description   : Bash script
#                 This script has been designed and written on Ubuntu 16.04 plateform.
#                 It must be executed in privileged mode
# Usage         : ./ceph-preflight.sh
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
VERSION=ceph-preflight-1.0-120217

# This script is executed in guest context
source "/vagrant/scripts/cephtest-utils.sh"
# Directories (depending of the context)
GUEST_USER_DIR="/home/$CEPH_ADMIN_USER"
GUEST_USER_SSH_DIR="$GUEST_USER_DIR/.ssh"
GUEST_VAGRANT_SCRIPT_DIR="/vagrant/scripts"
GUEST_VAGRANT_SSH_DIR="/vagrant/.ssh"

# Make sure only root can run the script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Create user ceph-admin
useradd -m -s /bin/bash $CEPH_ADMIN_USER

# Make ceph-admin passwordless sudoer
echo "$CEPH_ADMIN_USER ALL = (root) NOPASSWD:ALL" | tee "/etc/sudoers.d/$CEPH_ADMIN_USER"
chmod 0440 "/etc/sudoers.d/$CEPH_ADMIN_USER"

# Copy ceph-admin ssh keys and ssh config from Vagrant synced folder (muste be created by vagrant-preflight script)
$CEPH_ADMIN_EXEC mkdir -p "$GUEST_USER_SSH_DIR"
$CEPH_ADMIN_EXEC chmod 700 "$GUEST_USER_SSH_DIR"
for FILE in id_rsa id_rsa.pub config; do
    $CEPH_ADMIN_EXEC rm -f "$GUEST_USER_SSH_DIR/$FILE"
    $CEPH_ADMIN_EXEC cp "$GUEST_VAGRANT_SSH_DIR/$CEPH_ADMIN_USER-$FILE" "$GUEST_USER_SSH_DIR/$FILE"
    $CEPH_ADMIN_EXEC chmod 644 "$GUEST_USER_SSH_DIR/$FILE"
done  
$CEPH_ADMIN_EXEC chmod 600 "$GUEST_USER_SSH_DIR/id_rsa"
# Copy ceph-admin public key in authorized_keys 
$CEPH_ADMIN_EXEC rm -f "$GUEST_USER_SSH_DIR/authorized_keys"
$CEPH_ADMIN_EXEC cp "$GUEST_VAGRANT_SSH_DIR/$CEPH_ADMIN_USER-id_rsa.pub" "$GUEST_USER_SSH_DIR/authorized_keys"
$CEPH_ADMIN_EXEC chmod 644 "$GUEST_USER_SSH_DIR/authorized_keys"

# Make debconf non interactive and set the right local
export DEBIAN_FRONTEND=noninteractive

# Install ceph repository 
wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
echo deb https://download.ceph.com/debian/ $(lsb_release -sc) main | tee /etc/apt/sources.list.d/ceph.list
apt-get update

# Install chrony for time synchronization, gdisk for GPT partitioning, 
# vnstat for network stats, htop for system monitor and ceph-deploy
apt-get -y install chrony gdisk vnstat htop ceph-deploy

# Modify /etc/hosts to allow ceph-deploy to resolve the guest
# Need to replace the loopback address by the real address
GUEST_NAME=$(hostname -s)
IP_ADDRESS=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
sed -i "s/127.0.0.1\t$GUEST_NAME\t$GUEST_NAME/$IP_ADDRESS\t$GUEST_NAME\t$GUEST_NAME/g" /etc/hosts

# Create partitions on journal disk for osd nodes only
for NODE in $OSD_NODES; do
    if [[ NODE == $GUEST_NAME ]]; then
        sgdisk --new=0:0:10G /dev/vda > /dev/null 2>&1
        sgdisk --new=0:0:20G /dev/vda > /dev/null 2>&1
        sgdisk --largest-new=0 /dev/vda > /dev/null 2>&1
        sgdisk --print /dev/vda
    fi
done

# Full update
#apt-get -y dist-upgrade
#apt-get -y autoremove
