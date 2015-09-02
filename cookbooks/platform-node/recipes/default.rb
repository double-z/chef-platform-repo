#
# Cookbook Name:: platform-node
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

platform_node = node['platform_node']

node_name = platform_node['fqdn']
node_service = platform_node['service'].gsub("_","-")

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

# Opscode-omnibus wants hostname == fqdn, so we have to do this grossness
execute 'force-hostname-fqdn' do
  command "hostname #{node_name}"
  action :run
  not_if { node_service == `/bin/hostname` }
end

# Needed for hostname to survive reboots
if node['platform_family'] == 'rhel'
  file '/etc/sysconfig/network' do
    action :create
    owner "root"
    group "root"
    mode "0644"
    content "NETWORKING=yes\nHOSTNAME=#{node_name}\n"
  end
end

chef_ingredient node_service do
  # version node['chef-server']['version']
  action :install
end

if ::File.exists?('/etc/chef/firstrun.lock')
  include_recipe "platform-node::#{node_service}"
end

file '/etc/chef/firstrun.lock' do
  action :create
  owner 'root'
  group 'root'
  mode '0644'
end
