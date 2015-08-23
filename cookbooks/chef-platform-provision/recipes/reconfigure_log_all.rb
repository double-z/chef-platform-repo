#
# Cookbook Name:: chef-platform-provision
# Recipe:: reconfigure_log_all
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved
# puts node['chef_platform']
require 'awesome_print'

chef_platform_provision "prod" do
  action :reconfigure
  platform_data node['chef_platform']
  log_all true
end