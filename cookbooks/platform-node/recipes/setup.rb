#
# Cookbook Name:: platform-node
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

platform_node = node['platform_node']

myhostname = platform_node['fqdn']
myservice = platform_node['service']

service 'hostname' do
  action :nothing
end

file '/etc/hostname' do
  action :create
  owner 'root'
  group 'root'
  mode '0644'
  content "#{myhostname}\n"
  notifies :restart, 'service[hostname]', :immediately
end

# Opscode-omnibus wants hostname == fqdn, so we have to do this grossness
execute 'force-hostname-fqdn' do
  command "hostname #{myhostname}"
  action :run
  not_if { myhostname == `/bin/hostname` }
end

# Needed for hostname to survive reboots
if node['platform_family'] == 'rhel'
  file '/etc/sysconfig/network' do
    action :create
    owner "root"
    group "root"
    mode "0644"
    content "NETWORKING=yes\nHOSTNAME=#{myhostname}\n"
  end
end

chef_ingredient myservice.gsub("_","-") do
  # version node['chef-server']['version']
  action :install
end
