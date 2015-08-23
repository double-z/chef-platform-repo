#
# Cookbook Name:: chef-platform-provision
# Recipe:: reconfigure
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved

chef_platform_provision "prod" do
  action :reconfigure
  platform_data node['chef_platform']
end