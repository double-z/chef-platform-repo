#
# Cookbook Name:: platform-node
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.


chef_ingredient 'chef-server' do
  # version node['chef-server']['version']
  action :install
  notifies :reconfigure, 'chef_ingredient[chef-server]', :immediately
end

file "/var/chef/cache/chef-server-core.firstrun" do
  action :create
end

directory '/etc/opscode/'

template '/etc/opscode/chef-server.rb' do
	local true
  source "/var/chef/cache/templates.d/chef-server.rb.erb"
  notifies :reconfigure, 'chef_ingredient[chef-server]', :immediately
end