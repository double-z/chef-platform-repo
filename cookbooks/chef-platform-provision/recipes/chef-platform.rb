#
# Cookbook Name:: chef-platform-provision
# Recipe:: scale
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved
# puts node['chef_platform']
require 'awesome_print'
ap node['chef_platform'], options = {
  :indent => -2,
  :color => {
    :hash  => :pale,
    :class => :white
  }
}
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

chef_platform_provision "prod" do
  action :allocate
  platform_data node['chef_platform']
  log_all true
end
