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

# Make debconf non interactive
export DEBIAN_FRONTEND=noninteractive
# Make sure we have the french locale
locale-gen fr_FR.UTF-8

# Install ceph repository (luminous version)
$OUTPUT_LOG "Install ceph repository (luminous version)"
wget -q -O- 'https://download.ceph.com/keys/release.asc' | apt-key add -
echo deb https://download.ceph.com/debian-luminous/ $(lsb_release -sc) main | tee /etc/apt/sources.list.d/ceph.list
apt-get update

# Install chrony for time synchronization, gdisk for GPT partitioning, 
# vnstat for network stats, htop for system monitor and ceph-deploy
$OUTPUT_LOG "Install chrony, gdisk, vnstat, htop, ceph-deploy"
apt-get -y install chrony gdisk vnstat htop ceph-deploy

# Configure chrony with admin node as server and osd nodes as clients
# Update chronyc password
$OUTPUT_LOG "Configure chrony with admin node as server and osd nodes as clients"
echo "1 chrony" > /etc/chrony/chrony.keys
if [[ $GUEST_NAME == $ADMIN_NODE ]]; then
    sed -i "s/#local stratum/local stratum/g" /etc/chrony/chrony.conf
    sed -i "s/#allow 10\/8/allow 192.168\/16/g" /etc/chrony/chrony.conf
else
    sed -i "s/pool/server $ADMIN_NODE\n#pool/" /etc/chrony/chrony.conf
fi
# Restart chrony with new config
systemctl restart chrony

# Full update
#apt-get -y dist-upgrade
#apt-get -y autoremove

# Create partitions on journal disk for osd nodes only
$OUTPUT_LOG "Create partitions on journal disk for osd nodes"
for NODE in $OSD_NODES; do
    if [[ $NODE == $GUEST_NAME ]]; then
        $OUTPUT_LOG "Create partitions on $NODE"
        sgdisk --zap-all
        sgdisk --new=0:0:10G /dev/vda > /dev/null 2>&1
        sgdisk --largest-new=0 /dev/vda > /dev/null 2>&1
        sgdisk --print /dev/vda
    fi
done

# Modify /etc/hosts to allow ceph-deploy to resolve the guest
IP_ADDRESS=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
# Need to replace the loopback address by the real address
$OUTPUT_LOG "Modify /etc/hosts to allow ceph-deploy to resolve the guest"
sed -i "s/127.0.0.1\t$GUEST_NAME\t$GUEST_NAME/$IP_ADDRESS\t$GUEST_NAME\t$GUEST_NAME/g" /etc/hosts
echo >> /etc/hosts

# Signal that IP is ready
$OUTPUT_LOG "Signal that IP is ready"
echo -e "$IP_ADDRESS\t$GUEST_NAME" | tee "$GUEST_VAGRANT_SIGNAL_DIR/$GUEST_NAME-IP"

# Wait for all nodes IP and update /etc/hosts
$OUTPUT_LOG "Wait for all nodes IP and update /etc/hosts"
TIMER_MAX=300
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
        $OUTPUT_LOG "Add IP for $NODE"
        cat "$GUEST_VAGRANT_SIGNAL_DIR/$NODE-IP" | tee -a /etc/hosts
    fi
done

# Create user ceph-admin if not existing
$OUTPUT_LOG "Create user ceph-admin if not existing and make it paswordless sudoer"
cat /etc/passwd | grep $CEPH_ADMIN_USER || useradd -m -s /bin/bash $CEPH_ADMIN_USER

# Make ceph-admin passwordless sudoer
echo "$CEPH_ADMIN_USER ALL = (root) NOPASSWD:ALL" | tee "/etc/sudoers.d/$CEPH_ADMIN_USER"
chmod 0440 "/etc/sudoers.d/$CEPH_ADMIN_USER"

# Copy ceph-admin ssh keys and ssh config from Vagrant folder
# Keys must be created by pre-up script
# Executed in ceph admin context
$OUTPUT_LOG "Copy ssh keys, config and authorized keys"
$OUTPUT_LOG "Switch to $CEPH_ADMIN_USER context"
sudo -i -u $CEPH_ADMIN_USER << CEPHADMINBLOCK
    mkdir -p $GUEST_USER_SSH_DIR
    chmod 700 $GUEST_USER_SSH_DIR
    cd $GUEST_USER_SSH_DIR
    rm -f id_rsa id_rsa.pub config authorized_keys
    cp $GUEST_VAGRANT_SSH_DIR/$CEPH_ADMIN_USER-id_rsa id_rsa
    cp $GUEST_VAGRANT_SSH_DIR/$CEPH_ADMIN_USER-id_rsa.pub id_rsa.pub
    cp $GUEST_VAGRANT_SSH_DIR/$CEPH_ADMIN_USER-id_rsa.pub authorized_keys
    cp $GUEST_VAGRANT_SSH_DIR/$CEPH_ADMIN_USER-config config
    chmod 644 id_rsa.pub config authorized_keys
    chmod 600 id_rsa
CEPHADMINBLOCK
$OUTPUT_LOG "Switch to $(whoami) context"

# Signal that provision is done
$OUTPUT_LOG "Signal that provision is done"
echo "$(date --rfc-3339=ns) - Done!"  | tee "$GUEST_VAGRANT_SIGNAL_DIR/$GUEST_NAME-PROVISION"
