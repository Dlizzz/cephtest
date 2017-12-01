# -*- mode: ruby -*-

Vagrant.configure("2") do |config|

	config.vm.box = "bento/ubuntu-17.04"

	config.vm.provider :libvirt do |libvirt|
		libvirt.memory = 1024
		libvirt.volume_cache = "writeback"
		libvirt.graphics_type = "spice"
		libvirt.video_type = "qxl"
	end

	config.vm.define "admin", primary: true do |admin|
		admin.vm.hostname = "admin.local"		
	end

	config.vm.define "osd1" do |osd1|
		osd1.vm.hostname = "osd1.local"
		osd1.vm.network :private_network,
      		:type => "dhcp",
      		:libvirt__dhcp_start => "172.28.128.10",
      		:libvirt__dhcp_stop => "172.28.128.250",
      		:libvirt__network_address => "172.28.128.0",
      		:libvirt__domain_name => "osd.private",
      		:libvirt__network_name => "osd-private"
		osd1.vm.provider :libvirt do |libvirt|
			libvirt.storage :file, 
				:size => "40G", 
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

	config.vm.define "osd2" do |osd2|
		osd2.vm.hostname = "osd2.local"
		osd2.vm.network :private_network,
      		:type => "dhcp",
      		:libvirt__dhcp_start => "172.28.128.10",
      		:libvirt__dhcp_stop => "172.28.128.250",
      		:libvirt__network_address => "172.28.128.0",
      		:libvirt__domain_name => "osd.private",
      		:libvirt__network_name => "osd-private"
		osd2.vm.provider :libvirt do |libvirt|
			libvirt.storage :file, 
				:size => "40G", 
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
