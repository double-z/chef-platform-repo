#
# Cookbook Name:: chef-platform-provision
# Recipe:: scale
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved
# puts node['chef_platform']
require 'awesome_print'

# # Make This Work
# chef_platform_provision "prod" do
# 	driver "aws"
# 	api_fqdn "api.domain.name"
# 	topology "tier"
# 	server_frontends 3
# 	with_analytics true
# 	with_supermarket true
# 	# and/or
# 	analytics_fqdn "analytics.domain.name"
# 	supermarket_fqdn "supermarket.domain.name"
# end

chef_platform_provision "prod" do
  action :allocate
  platform_data node['chef_platform']
  log_all true
end





##
# LOG OUT SHIT:

# ap node['chef_platform'], options = {
#   :indent => -2,
#   :color => {
#     :hash  => :pale,
#     :class => :white
#   }
# }
# file "#{Chef::Config[:chef_repo_path]}/chef-platform-spec.json" do

#   # file_content = {
#   #   "chef_platform" => node['chef_platform'].to_hash
#   # }
#   content lazy { Chef::JSONCompat.to_json_pretty({ "chef_platform" => node['chef_platform'].to_hash }) }
# end

# require 'yaml'
# file "#{Chef::Config[:chef_repo_path]}/chef-platform-spec.yml" do

#   file_content = {
#     "chef_platform" => node['chef_platform'].to_hash
#   }
#   content lazy { file_content.to_yaml }
# end
