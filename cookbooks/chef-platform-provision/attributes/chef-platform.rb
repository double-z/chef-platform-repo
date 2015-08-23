
default['chef_platform']['driver'].tap do |driver|
  driver['name'] = 'ssh'
end

default['chef_platform']['chef_server'].tap do |chef_server|
  chef_server['topology'] = "tier"
  chef_server['version'] = :latest
  chef_server['api_fqdn'] = "chef-server.chefplatform.local"
  chef_server['configuration'] = {
    "postgresql" => {
      "max_connections" => 1500,
      "log_min_duration_statement" => 500
    },
    # "oc_id" => {

    # },
    "opscode_erchef" => {
      "depsolver_worker_count" => 4,
      "depsolver_timeout" => 120000,
      "db_pool_size" => 100
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
  }

end

default['chef_platform']['analytics'].tap do |analytics|
  analytics['version'] = :latest
  analytics['api_fqdn'] = "analytics.chefplatform.local"
  analytics['configuration'] = {
    "actions_consumer" => {
      "hipchat_api_token" => "4yZvEWO6gnVhjtl3F6aU12obylgNXzzqmklI5jP0",
      "hipchat_enabled" => [
        "prod",
        "preprod"
      ],
      "hipchat_room" => 'Chef Notifications'
    }
  }
end

default['chef_platform']['supermarket'].tap do |supermarket|
  supermarket['version'] = :latest
  supermarket['api_fqdn'] = node['fqdn']
  supermarket['configuration'] = {}
end

default['chef_platform']['delivery'].tap do |delivery|
  delivery['version'] = :latest
  delivery['api_fqdn'] = node['fqdn']
  delivery['configuration'] = {}
end

default['chef_platform']['nodes'] = [
  {
    "node_name" => "backend1",
    "service" => "chef_server",
    "fqdn" =>"backend1.ubuntu.vagrant",
    "interface" => "eth1",
    "machine_options_ipaddress" => "33.33.33.20",
    "role" => "backend",
    "bootstrap" => true
  },
  {
    "node_name" => "frontend1",
    "service" => "chef_server",
    "fqdn" => "frontend1.ubuntu.vagrant",
    "interface" => "eth1",
    "machine_options_ipaddress" => "33.33.33.22",
    "role" => "frontend",
    "bootstrap" => false
  },
  {
    "node_name" => "analytics1",
    "service" => "analytics",
    "fqdn" => "analytics.ubuntu.vagrant",
    "interface" => "eth1",
    "machine_options_ipaddress" => "33.33.33.25",
    "role" => "analytics",
    "bootstrap" => false
  }
]



# end


# default['chef_platform'].tap do |chef_platform|

#   chef_platform['driver'].tap do |driver|
#     driver['name'] = 'vagrant'
#     driver['machine_options'] = {
#       "vagrant_config" => {
#         "machine" => "centos6"
#       }
#     }
#   end

#   # default['chef_platform']['chef_server'].tap do |chef_server|
#   chef_platform['chef_server'].tap do |chef_server|
#     chef_server['version'] = :latest
#     chef_server['prereleases'] = false
#     chef_server['nightlies'] = false
#     chef_server['package_file'] = nil
#     chef_server['package_checksum'] = nil
#     chef_server['api_fqdn'] = node['fqdn']
#     chef_server['machine_options'] = {
#       "vagrant_config" => {
#         "machine" => "centos6"
#       }
#     }
#     chef_server['configuration'] = {}
#   end

#   chef_platform['analytics'].tap do |analytics|
#     analytics['version'] = :latest
#     analytics['prereleases'] = false
#     analytics['nightlies'] = false
#     analytics['package_file'] = nil
#     analytics['package_checksum'] = nil
#     analytics['api_fqdn'] = node['fqdn']
#     analytics['machine_options'] = {
#       "vagrant_config" => {
#         "machine" => "centos6"
#       }
#     }
#     analytics['configuration'] = {}
#   end

#   chef_platform['supermarket'].tap do |supermarket|
#     supermarket['version'] = :latest
#     supermarket['prereleases'] = false
#     supermarket['nightlies'] = false
#     supermarket['package_file'] = nil
#     supermarket['package_checksum'] = nil
#     supermarket['api_fqdn'] = node['fqdn']
#     supermarket['machine_options'] = {
#       "vagrant_config" => {
#         "machine" => "centos6"
#       }
#     }
#     supermarket['configuration'] = {}
#   end

#   chef_platform['delivery'].tap do |delivery|
#     delivery['version'] = :latest
#     delivery['prereleases'] = false
#     delivery['nightlies'] = false
#     delivery['package_file'] = nil
#     delivery['package_checksum'] = nil
#     delivery['api_fqdn'] = node['fqdn']
#     delivery['machine_options'] = {
#       "vagrant_config" => {
#         "machine" => "centos6"
#       }
#     }
#     delivery['configuration'] = {}
#   end

#   chef_platform['nodes'].tap do |nodes|
#     nodes = [
#       {
#         "node_name" = "backend1",
#         "service" = "chef_server",
#         "fqdn" = "backend1.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.21",
#         "cluster_ipaddress" = "33.33.34.5",
#         "role" = "backend",
#         "bootstrap" = true
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "backend2",
#         "service" = "chef_server",
#         "fqdn" = "backend1.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.31",
#         "cluster_ipaddress" = "33.33.34.4",
#         "role" = "backend",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "frontend1",
#         "service" = "chef_server",
#         "fqdn" = "frontend1.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.22",
#         "role" = "frontend",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "frontend2",
#         "service" = "chef_server",
#         "fqdn" = "frontend2.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.23",
#         "role" = "frontend",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "frontend3",
#         "service" = "chef_server",
#         "fqdn" = "frontend3.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.24",
#         "role" = "frontend",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "analytics1",
#         "service" = "analytics",
#         "fqdn" = "analytics.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.25",
#         "role" = "analytics",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "supermarket1",
#         "service" = "supermarket",
#         "fqdn" = "supermarket.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.26",
#         "role" = "supermarket",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "delivery-server1",
#         "service" = "delivery",
#         "fqdn" = "delivery-server1.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.27",
#         "role" = "delivery_server",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "delivery-build1",
#         "service" = "delivery",
#         "fqdn" = "delivery-build1.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.28",
#         "role" = "delivery_build",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       },
#       {
#         "node_name" = "delivery-build2",
#         "service" = "delivery",
#         "fqdn" = "delivery-build2.ubuntu.vagrant",
#         "ipaddress" = "33.33.33.23",
#         "role" = "delivery_build",
#         "bootstrap" = false,
#         "machine_options" = {
#           "vagrant_config" => {
#             "machine" => "centos6"
#           }
#         }
#       }
#     ]
#   end

# end


#################################################################################
# # Load chef_platform attributes from the config file
# chef_platform_dir = Chef::Config[:chef_repo_path]
# config_json = JSON.parse(File.read(File.join(chef_platform_dir, 'config-default.json')))

# default['chef_platform'].tap do |chef_platform|

#    chef_platform['driver'].tap do |driver|
#     driver['name'] = chef_platform_dir
#     driver['machine_options'] = File.join(chef_platform_dir, 'vagrant_vms')
#   end

#    chef_platform['nodes'].tap do |driver|
#     driver['name'] = chef_platform_dir
#     driver['machine_options'] = File.join(chef_platform_dir, 'vagrant_vms')
#   end

#   # chef_platform_DIR is set by the Rakefile to the project root directory
#   # TODO reduntant standardize
#   chef_platform['chef_server'].tap do |chef_server|
#     chef_server['repo_path'] = chef_platform_dir
#     chef_server['vms_dir'] = File.join(chef_platform_dir, 'vagrant_vms')
#   end

#   # host_cache_path is mapped to /tmp/cache on the VMs
#   # Used to push down packages
#   # TODO Move to machine_file and eliminate
#   chef_platform['host_cache_path'] = File.join(chef_platform_dir, 'cache')
#   chef_platform['vm_mountpoint'] = '/tmp/ecm_cache'

#   # SSH key distribution for inter-machine trust
#   # TODO move file retrieval to machine_file and eliminate
#   chef_platform['root_ssh'] = {
#     'privkey' => File.read(File.join(chef_platform_dir, 'keys', 'id_rsa')),
#     'pubkey' => File.read(File.join(chef_platform_dir, 'keys', 'id_rsa.pub'))
#   }


#   chef_platform['root_ssh']['pubkey'] = File.read(File.join(chef_platform_dir, 'keys', 'id_rsa.pub'))

#   # TODO Rename to driver
#   chef_platform['provider'] = config_json['provider']
#   chef_platform['vagrant'] = config_json['vagrant_options']
#   chef_platform['ec2'] = config_json['ec2_options']
#   chef_platform['vm_config'] = config_json['layout']
#   # TODO Eliminate default.
#   chef_platform['default_package'] = config_json['default_package']
#   chef_platform['run_pedant'] = config_json['run_pedant'] || true
#   # TODO factor out and only support current as of now on
#   chef_platform['osc_install'] = config_json['osc_install'] || false
#   chef_platform['osc_upgrade'] = config_json['osc_upgrade'] || false
#   chef_platform['packages'] = config_json['packages']

#   # Provide an option to not monkeypatch the bugfixes
#   # TODO Deprecate
#   chef_platform['apply_ec_bugfixes'] = config_json['apply_ec_bugfixes'] || false

#   # Provide an option to intentionally bomb out before running the upgrade reconfigure, so it can be done manually
#   chef_platform['vm_config']['lemme_doit'] = config_json['lemme_doit'] || false

#   # Provide an option to run the "org torturer" which creates 900 orgs.  see: https://gist.github.com/irvingpop/bf4b983b5db7b5b9cbc7
#   chef_platform['org_torture'] = config_json['org_torture'] || false

#   # addon packages
#   # TODO refactor so as to determine by distro/arch/version
#   chef_platform['manage_package'] = config_json['manage_package']
#   chef_platform['reporting_package'] = config_json['reporting_package']
#   chef_platform['pushy_package'] = config_json['pushy_package']
#   chef_platform['analytics_package'] = config_json['analytics_package']

#   # manage options
#   chef_platform['manage_options'] = config_json['manage_options'] || {}

#   # loadtesters config
#   chef_platform['loadtesters'] = config_json['loadtesters']
# end


# server = [
#   {
#     "fqdn" => "",
#     "role" => "",
#     "" => "",
#     "" => "",
#     "" => "",
#     "" => "",
#     "" => "",
#     "" => "",
#     "" => ""
#   }
# ]
# default['chef_platform'].tap do |chef_platform|
