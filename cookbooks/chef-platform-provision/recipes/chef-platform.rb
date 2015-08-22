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
    # cluster_size "small" # small is 0-500 medium 500-2000 large 2000-5000 extra large 5000+ supersize 15000+
# 	api_fqdn "api.domain.name"
# 	topology "tier"
# 	server_frontends 3
# 	with_analytics true
# 	with_supermarket true
# 	# and/or
# 	analytics_fqdn "analytics.domain.name"
# 	supermarket_fqdn "supermarket.domain.name"
# end
ruby_block 'before_puts' do
  block do
  	puts "IN RECIPE BEFORE"
  	puts "IN RECIPE BEFORE"
  	puts "IN RECIPE BEFORE"
  	puts "IN RECIPE BEFORE"
  	puts "IN RECIPE BEFORE"
  	puts "IN RECIPE BEFORE"
  	puts "IN RECIPE BEFORE"
  end
  action :run
end

puts node['chef_platform']['chef_server']['configuration']

chef_platform_provision "prod" do
  action :reconfigure
  # action :destroy_all
  platform_data node['chef_platform']
  # log_all true
end


ruby_block 'after_puts' do
  block do
  	puts "IN RECIPE AFTER"
  	puts "IN RECIPE AFTER"
  	puts "IN RECIPE AFTER"
  	puts "IN RECIPE AFTER"
  	puts "IN RECIPE AFTER"
  	puts "IN RECIPE AFTER"
  	puts "IN RECIPE AFTER"
  end
  action :run
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
