#
# Cookbook Name:: chef-platform-provision
# Recipe:: destroy_all
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved

chef_platform_provision "prod" do
  action :destroy_all
  platform_data node['chef_platform']
end