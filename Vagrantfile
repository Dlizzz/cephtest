# -*- mode: ruby -*-

Vagrant.configure("2") do |config|

	# Get the VagrantFile directory
	vagrant_root = File.dirname(__FILE__)
	
	# Trigger the Vagrant pre-up script before uping the first VM only
	config.trigger.before :up, :vm => ["node-admin"], :append_to_path => ["#{vagrant_root}/scripts"] do
		run "pre-up.sh"
	end

	# Shell provisionner for all VMs
	config.vm.provision "ceph-preflight", type: "shell", path: "scripts/provision.sh"
	
	# All VMs are based on the same box
	config.vm.box = "bento/ubuntu-16.04"

	# Use nfs for shared folder
	config.vm.synced_folder ".", "/vagrant",
  		nfs: true,
		linux__nfs_options: ['rw','no_subtree_check','all_squash','async'],
		nfs_version: 4,
		nfs_udp: false

	# Public host bridge
	# config.vm.network "public_network", 
	#	network_name: "public-network",
	#	dev: "br0", 
	#	type: "bridge", 
	#	mode: "bridge"

	# Standard configuration for all VMs
	config.vm.provider :libvirt do |libvirt|
		libvirt.memory = 2048
		libvirt.volume_cache = "writeback"
		libvirt.graphics_type = "spice"
		libvirt.video_type = "qxl"
	end

	# admin VM
	config.vm.define "node-admin", primary: true do |admin|
		admin.vm.hostname = "node-admin"
		admin.vm.provision "ceph-install", type: "shell", keep_color: true, path: "scripts/provision-admin.sh"
	end

	# osd1 VM with private cluster network
	# 3 additional disks: 1 for journals and 2 for osd
	config.vm.define "node-osd1" do |osd1|
		osd1.vm.hostname = "node-osd1"
		osd1.vm.network :private_network,
			:type => "dhcp",
			:mac => "52:54:00:79:1e:b0",  
      		:libvirt__dhcp_start => "172.28.128.10",
      		:libvirt__dhcp_stop => "172.28.128.250",
			:libvirt__network_address => "172.28.128.0",
			:libvirt__netmask => "255.255.255.0",
      		:libvirt__network_name => "cluster-network"
		osd1.vm.provider :libvirt do |libvirt|
			libvirt.storage :file, 
				:size => "30G", 
				:type => "raw",
				:cache => "writeback"
			libvirt.storage :file, 
				:size => "20G", 
				:type => "raw",
				:cache => "writeback"
			libvirt.storage :file, 
				:size => "20G", 
				:type => "raw",
				:cache => "writeback"
		end
	end

	# osd2 VM with private cluster network
	# 3 additional disks: 1 for journals and 2 for osd
	config.vm.define "node-osd2" do |osd2|
		osd2.vm.hostname = "node-osd2"
		osd2.vm.network :private_network,
			:type => "dhcp",
			:mac => "52:54:00:dc:51:7c",  
			:libvirt__network_name => "cluster-network"
		osd2.vm.provider :libvirt do |libvirt|
			libvirt.storage :file, 
				:size => "30G", 
				:type => "raw",
				:cache => "writeback"
			libvirt.storage :file, 
				:size => "20G", 
				:type => "raw",
				:cache => "writeback"
			libvirt.storage :file, 
				:size => "20G", 
				:type => "raw",
				:cache => "writeback"
		end
	end
end
