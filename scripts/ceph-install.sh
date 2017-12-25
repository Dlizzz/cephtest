#!/bin/bash
# ========================================================================================
# Execute ceph distributed storage installation steps from the admin node via ceph-deploy
#
# Written by    : Denis Lambolez
# Release       : 2.0
# Creation date : 18 December 2017
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
#       2.0     |    12.18.17   | Denis Lambolez | Make it a standalone provisioner
#       1.0     |    12.04.17   | Denis Lambolez | Creation
#               |               |                | 
#               |               |                | 
# =========================================================================================
#set -xv

# Version
VERSION=ceph-install-2.0-121817

# This script is executed in guest context
source "/vagrant/scripts/cephtest-utils.sh"

# Make sure only root can run the script
if [[ $(whoami) != $CEPH_ADMIN_USER ]]; then
   echo "This script must be run as $CEPH_ADMIN_USER" >&2
   exit 1
fi

# Network (dynamically defined by Vagrant)
IP_ADDRESS=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
PUBLIC_NETWORK=$(echo $IP_ADDRESS | awk -F '.' '{print $1"."$2"."$3".0/24"}')

# Cluster configuration directory
$OUTPUT_LOG "Create new cluster configuration"
mkdir -p "$GUEST_USER_DIR/ceph-cluster"
cd "$GUEST_USER_DIR/ceph-cluster"

# Create cluster
ceph-deploy new $ADMIN_NODE

# Initialize cluster configuration
$OUTPUT_LOG "Initialize cluster configuration"
cat << CLUSTERCONFIG | tee -a ceph.conf
public network = $PUBLIC_NETWORK
cluster network = $CLUSTER_NETWORK

osd pool default size = 2
osd pool default min size = 1
osd pool default pg num = 128 
osd pool default pgp num = 128
CLUSTERCONFIG

for NODE in $OSD_NODES; do
cat << CLUSTERCONFIG | tee -a ceph.conf

[mds.$NODE]
mds standby replay = true
mds standby for rank = 0
CLUSTERCONFIG
done

# Deploy ceph on all nodes
$OUTPUT_LOG "Deploy ceph on all nodes"
ceph-deploy install --release luminous $NODES

# Create initial monitor
$OUTPUT_LOG "Create initial monitor"
ceph-deploy --overwrite-conf mon create-initial

# Deploy configuration file and client keys
$OUTPUT_LOG "Deploy configuration file and client keys on all nodes"
ceph-deploy admin $NODES

# Add monitor on osd nodes
for NODE in $OSD_NODES; do
    $OUTPUT_LOG "Add monitor on $NODE"
    ceph-deploy mon add $NODE
done 

# Create manager on all nodes
$OUTPUT_LOG "Create manager on all nodes"
ceph-deploy mgr create $NODES

# Create metadata server on osd nodes
$OUTPUT_LOG "Create metadata server on osd nodes"
ceph-deploy mds create $OSD_NODES

# For each osd node, gather keys from admin node and create OSDs
for NODE in $OSD_NODES; do
    $OUTPUT_LOG "Gather keys on $NODE"
    ssh $NODE ceph-deploy gatherkeys $ADMIN_NODE
    ssh $NODE sudo cp /home/$CEPH_ADMIN_USER/ceph.bootstrap-osd.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
    ssh $NODE sudo chown ceph:ceph /var/lib/ceph/bootstrap-osd/ceph.keyring
    $OUTPUT_LOG "Create OSDs on $NODE"
    ssh $NODE sudo ceph-volume lvm create --filestore --data /dev/vdb --journal /dev/vda1
    ssh $NODE sudo ceph-volume lvm create --filestore --data /dev/vdc --journal /dev/vda2
done;

# wait 10 seconds and get cluster status
sleep 10
sudo ceph -s 

$OUTPUT_LOG "Ceph cluster is now ready for pool creation and other activities.\nThanks for waiting. Enjoy!"
