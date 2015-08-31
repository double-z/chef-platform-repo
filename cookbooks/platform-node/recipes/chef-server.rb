#
# Cookbook Name:: platform-node
# Recipe:: server
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "platform-node::setup"

directory '/etc/opscode' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  not_if 'test -d /etc/opscode'
end

template '/etc/opscode/chef-server.rb' do
  local true
  source "/var/chef/cache/platform/chef-server.rb.erb"
  notifies :reconfigure, 'chef_ingredient[chef-server]', :immediately
end
