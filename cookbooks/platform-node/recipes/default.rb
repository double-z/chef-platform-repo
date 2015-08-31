#
# Cookbook Name:: platform-node
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

action = node['platform_action'] || false

if action
  include_recipe "platform-node::#{action}"
end

# if node['platform_node']
#   file '/etc/platform_data.json' do
#     action :create
#     owner 'root'
#     group 'root'
#     mode '0644'
#     content Chef::JSONCompat.to_json_pretty(
#       'platform_node' => node['platform_node'].to_hash
#     )
#   end
# end
