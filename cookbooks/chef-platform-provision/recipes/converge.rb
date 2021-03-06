#
# Cookbook Name:: chef-platform-provision
# Recipe:: reconfigure
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved

chef_platform_provision "prod" do
  action :reconfigure
  driver_name 'vagrant'
  chef_server_topology "tier"
  chef_server_version :latest
  chef_server_api_fqdn "frontend1.chef-platform.local"
  chef_server_configuration({ 
      "postgresql" => {
        "max_connections" => 301,
        "log_min_duration_statement" => 500
      },
      "opscode_erchef" => {
        "depsolver_worker_count" => 4,
        "depsolver_timeout" => 120000,
        "db_pool_size" => 100
      },
      "folsom_graphite" => {
        "enabled" => true,
        "host" => '192.168.33.41',
        "port" => 2003
      },
      "oc_bifrost" => {
        "db_pool_size" => 100
      },
      "opscode_certificate" => {
        "num_workers" => 4,
        "num_certificates_per_worker" => 1000
      },
      "oc_chef_authz" => {
        "http_init_count" => 150,
        "http_max_count" => 150
      }
    })
  analytics_version :latest
  analytics_api_fqdn "analytics.chefplatform.local"
  analytics_configuration({
      "actions_consumer" => {
        "hipchat_api_token" => "4yZvEWO6gnVhjtl3F6aU12obylgNXzzqmklI5jP0",
        "hipchat_enabled" => [
          "prod",
          "preprod"
        ],
        "hipchat_room" => 'Chef Notifications'
      }
    })
  nodes([
      {
        "node_name" => "backend1",
        "service" => "chef_server",
        "fqdn" =>"backend1.chef-platform.local",
        "interface" => "eth1",
        "machine_options_ipaddress" => "33.33.33.20",
        "role" => "backend",
        "bootstrap" => true
      },
      {
        "node_name" => "frontend1",
        "service" => "chef_server",
        "fqdn" => "frontend1.chef-platform.local",
        "interface" => "eth1",
        "machine_options_ipaddress" => "33.33.33.22",
        "role" => "frontend",
        "bootstrap" => false
      },
      {
        "node_name" => "analytics1",
        "service" => "analytics",
        "fqdn" => "analytics.chef-platform.local",
        "interface" => "eth1",
        "machine_options_ipaddress" => "33.33.33.25",
        "role" => "analytics",
        "bootstrap" => false
      }
    ])
end
