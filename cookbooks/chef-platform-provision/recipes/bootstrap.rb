#
# Cookbook Name:: chef-platform-provision
# Recipe:: bootstrap
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved.

file "/var/opt/chef-provisioner/etc/opscode/private-chef-secrets.json" do
  content JSON.pretty_generate(chef_secrets)
  notifies :run, 'ruby_block[notify_bootstrap]'
  sensitive true
end

file "/var/opt/chef-provisioner/etc/opscode-reporting/#{context.policy_group}/opscode-reporting-secrets.json" do
  content JSON.pretty_generate(reporting_secrets)
  notifies :converge, "machine[#{topology.bootstrap_machine_name}]", :immediately
  sensitive true
end

template "/var/opt/chef-provisioner/etc/opscode/#{context.policy_group}/chef-server.rb" do
  source 'chef-server.rb.erb'
  variables lazy (:chef_server_config => node['chef-platform']['server'],
                  :chef_servers => topology.chef_servers
                  )
  notifies :converge, "machine[#{topology.bootstrap_machine_name}]" #, :immediately
end
