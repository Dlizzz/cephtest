# -*- mode: ruby -*-

Vagrant.configure("2") do |config|

	# Get the VagrantFile directory
	vagrant_root = File.dirname(__FILE__)
	
	# Trigger the Vagrant preflight script before uping the first VM only
	config.trigger.before :up, :vm => ["node-admin"], :append_to_path => ["#{vagrant_root}/scripts"] do
		run "vagrant-preflight.sh"
	end

	# Shell provisionner for all VMs
	config.vm.provision "shell", path: "scripts/ceph-preflight.sh"
	
	# All VMs are based on the same box
	config.vm.box = "bento/ubuntu-16.04"

	# Standard configuration for all VMs
	config.vm.provider :libvirt do |libvirt|
		libvirt.memory = 1024
		libvirt.volume_cache = "writeback"
		libvirt.graphics_type = "spice"
		libvirt.video_type = "qxl"
	end

	# Define bridged public network
	config.vm.network :public_network,
		:dev => "eno1",
		:mode => "bridge",
		:type => "bridge",
		:network_name => "public-net"

	# admin VM
	config.vm.define "node-admin", primary: true do |admin|
		admin.vm.hostname = "node-admin"		
	end

	# osd1 VM with private cluster network
	# 5 additional disks: 1 for ceph journal and 4 for osd
	config.vm.define "node-osd1" do |osd1|
		osd1.vm.hostname = "node-osd1"
		osd1.vm.network :private_network,
      		:type => "dhcp",
      		:libvirt__dhcp_start => "172.28.128.10",
      		:libvirt__dhcp_stop => "172.28.128.250",
			:libvirt__network_address => "172.28.128.0",
			:libvirt__netmask => "255.255.255.0",
      		:libvirt__network_name => "cluster-net"
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
	# 5 additional disks: 1 for ceph journal and 4 for osd
	config.vm.define "node-osd2" do |osd2|
		osd2.vm.hostname = "node-osd2"
		osd2.vm.network :private_network,
      		:type => "dhcp",
			:libvirt__network_name => "cluster-net"
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
