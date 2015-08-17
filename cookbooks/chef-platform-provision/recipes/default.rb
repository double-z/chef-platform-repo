#
# Cookbook Name:: chef-platform-provision
# Recipe:: default
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved.



# pp "node['harness']"
# require 'chef/provisioning/vagrant_driver'

# harness_dir = node['harness']['harness_dir']
# repo_path = node['harness']['repo_path']
# vms_dir = node['harness']['vms_dir']
# directory vms_dir
# vagrant_cluster vms_dir

# directory repo_path
# with_chef_local_server :chef_repo_path => repo_path,
#   :cookbook_path => [ File.join(harness_dir, 'cookbooks'),
#                       File.join(repo_path, 'cookbooks'),
#                       File.join(repo_path, 'vendor', 'cookbooks') ],
#   :port => 9010.upto(9999)

# chef_platform_provision "prod" do
#   action :deploy
# end