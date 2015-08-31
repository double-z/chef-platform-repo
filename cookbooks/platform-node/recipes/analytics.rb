#
# Cookbook Name:: platform-node
# Recipe:: analytics
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "platform-node::setup"

directory '/etc/opscode-analytics' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  not_if 'test -d /etc/opscode-analytics'
end

template '/etc/opscode-analytics/analytics.rb' do
  local true
  source "/var/chef/cache/platform/analytics.rb.erb"
  notifies :reconfigure, 'chef_ingredient[analytics]', :immediately
end
