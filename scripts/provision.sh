#!/bin/bash
# ========================================================================================
# Execute preflight configuration needed to deploy ceph distributed storage
#
# Written by    : Denis Lambolez
# Release       : 2.0
# Creation date : 17 December 2017
# Description   : Bash script
#                 This script has been designed and written on Ubuntu 16.04 plateform.
#                 It must be executed in privileged mode
# Usage         : ./provision.sh
# ----------------------------------------------------------------------------------------
# ========================================================================================
#
# HISTORY :
#     Release   |     Date      |    Authors     |       Description
# --------------+---------------+--------------- +------------------------------------------
#       2.0     |    12.17.17   | Denis Lambolez | Adding /etc/hosts modification and 
#               |               |                | synchronization with other nodes. Renamed 
#               |               |                | to provision.sh 
#       1.1     |    12.04.17   | Denis Lambolez | Sourcing parameters from cephtest-utils
#       1.0     |    12.02.17   | Denis Lambolez | Creation
#               |               |                | 
# =========================================================================================
#set -xev

# Version
VERSION=provision-2.0-121717

# This script is executed in guest context
source "/vagrant/scripts/cephtest-utils.sh"

# Make sure only root can run the script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Create user ceph-admin if not existing
cat /etc/passwd | grep $CEPH_ADMIN_USER
if [[ $? -ne 0 ]]; then
    useradd -m -s /bin/bash $CEPH_ADMIN_USER
fi

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

# Modify /etc/hosts to allow ceph-deploy to resolve the guests
IP_ADDRESS=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
# Need to replace the loopback address by the real address
sed -i "s/127.0.0.1\t$GUEST_NAME\t$GUEST_NAME/$IP_ADDRESS\t$GUEST_NAME\t$GUEST_NAME/g" /etc/hosts

# Create partitions on journal disk for osd nodes only
for NODE in $OSD_NODES; do
    if [[ $NODE == $GUEST_NAME ]]; then
        sgdisk --zap-all
        sgdisk --new=0:0:10G /dev/vda > /dev/null 2>&1
        sgdisk --new=0:0:20G /dev/vda > /dev/null 2>&1
        sgdisk --largest-new=0 /dev/vda > /dev/null 2>&1
        sgdisk --print /dev/vda
    fi
done

# Full update
#apt-get -y dist-upgrade
#apt-get -y autoremove

# Signal that IP is ready
echo -e "$IP_ADDRESS\t$GUEST_NAME" > "$GUEST_VAGRANT_SIGNAL_DIR/$GUEST_NAME-IP"

# Wait for all nodes IP and update /etc/hosts
TIMER_MAX=300
echo >> /etc/hosts
for NODE in $NODES; do
    if [[ $NODE != $GUEST_NAME ]]; then
        TIMER=0
        until [[ -r "$GUEST_VAGRANT_SIGNAL_DIR/$NODE-IP" ]]; do
            sleep 1
            TIMER=$(($TIMER + 1))
            if [[ $TIMER -gt $TIMER_MAX ]]; then
                echo "Can't get IP from $NODE" >&2
                exit 1
            fi
        done
        # Remove record if existing
        sed -i "/$NODE/d" /etc/hosts
        # Add new record
        cat "$GUEST_VAGRANT_SIGNAL_DIR/$NODE-IP" >> /etc/hosts
    fi
done

# Signal that provision is done
echo "$(date --rfc-3339=ns) - Done!"  | tee "$GUEST_VAGRANT_SIGNAL_DIR/$GUEST_NAME-PROVISION"

# Continue provisioning on admin node only
[[ $GUEST_NAME != $ADMIN_NODE ]] && exit 0

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
 
# Install ceph in ceph-admin context
$CEPH_ADMIN_EXEC $GUEST_VAGRANT_SCRIPT_DIR/ceph-install.sh
