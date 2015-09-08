#
# Cookbook Name:: platform-node
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.


if node['platform_node']
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts node['platform_node']
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts "node['platform_node']"
  puts "node['platform_node']"
else
  puts "NOPE"
  puts "NOPE"
  puts "NOPE"
  puts "NOPE"
  puts "NOPE"
  puts "NOPE"
end

first_run_lock = ::File.exists?('/etc/chef/firstrun.lock')

if !first_run_lock
  file '/etc/chef/firstrun.lock' do
    action :create
    owner 'root'
    group 'root'
    mode '0644'
  end
else
  platform_node = node['platform_node']
  node_name = platform_node['fqdn']
  node_service = platform_node['service'].gsub("_","-")

  node['chef_platform']['nodes'].each do |node_data|
    hostsfile_entry node_data['ipaddress'] do
      hostname node_data['fqdn']
      unique true
    end
  end

  service 'hostname' do
    action :nothing
  end

  file '/etc/hostname' do
    action :create
    owner 'root'
    group 'root'
    mode '0644'
    content "#{node_name}\n"
    notifies :restart, 'service[hostname]', :immediately
  end

  execute 'force-hostname-fqdn' do
    command "hostname #{node_name}"
    action :run
    not_if { node_service == `/bin/hostname` }
  end

  if node['platform_family'] == 'rhel'
    file '/etc/sysconfig/network' do
      action :create
      owner "root"
      group "root"
      mode "0644"
      content "NETWORKING=yes\nHOSTNAME=#{node_name}\n"
    end
  end

  if first_run_lock
    chef_ingredient node_service do
      # version node['chef-server']['version']
      action :install
    end

    include_recipe "platform-node::#{node_service}"
  end
end
