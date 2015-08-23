# Policyfile.rb - Describe how you want Chef to build your system.
#
# For more information on the Policyfile feature, visit
# https://github.com/opscode/chef-dk/blob/master/POLICYFILE_README.md

# A name that describes what the system you're building with Chef does.
name "cchef_platform"

# Where to find external cookbooks:
default_source :community

# run_list: chef-client will run these recipes in the order specified.
run_list "private-chef::default"

cookbook "private-chef", path: "./cookbooks/private-chef"
cookbook "ec-common", path: "./cookbooks/ec-common"
cookbook "apt", path: "./vendor/cookbooks/apt"
cookbook "aws", path: "./vendor/cookbooks/aws"
cookbook "chef-client", path: "./vendor/cookbooks/chef-client"
cookbook "chef_handler", path: "./vendor/cookbooks/chef_handler"
cookbook "cron", path: "./vendor/cookbooks/cron"
cookbook "docker", path: "./vendor/cookbooks/docker"
cookbook "ec-tools", path: "./vendor/cookbooks/ec-tools"
cookbook "hostsfile", path: "./vendor/cookbooks/hostsfile"
cookbook "logrotate", path: "./vendor/cookbooks/logrotate"
cookbook "lvm", path: "./vendor/cookbooks/lvm"
cookbook "windows", path: "./vendor/cookbooks/windows"
cookbook "yum", path: "./vendor/cookbooks/yum"
cookbook "yum-elrepo", path: "./vendor/cookbooks/yum-elrepo"
cookbook "yum-epel", path: "./vendor/cookbooks/yum-epel"

##
# Configurable Attributes
#
# - These are settings that commonly tuned
#
##

override['chef_platform'] = {
  "configurables" => {

  }
}

##
# Default Attributes
#
# - These should be good except for all but very specific use cases
#
#   *** DO NOT EDIT outside of very specific need ***
#
##

default["chef_platform"] =  {
  "chef_server" => {
    "version" => "latest",
    "prereleases"      => false,
    "nightlies"        => false,
    "package_file"     => nil,
    "package_checksum" => nil,
    "api_fqdn"         => "js4",
    "configuration"    => {
      "postgresql"          => {
        "max_connections"            => 1500,
        "log_min_duration_statement" => 500
      },
      "oc_id"               => {},
      "opscode_erchef"      => {
        "depsolver_worker_count" => 4,
        "depsolver_timeout"      => 120000,
        "db_pool_size"           => 100
      },
      "oc_bifrost"          => {
        "db_pool_size" => 100
      },
      "opscode_certificate" => {
        "num_workers"                 => 4,
        "num_certificates_per_worker" => 1000
      },
      "oc_chef_authz"       => {
        "http_init_count" => 150,
        "http_max_count"  => 150
      }
    }
  },
  "analytics" => {
    "version" => "latest",
    "prereleases"      => false,
    "nightlies"        => false,
    "package_file"     => nil,
    "package_checksum" => nil,
    "api_fqdn"         => "js4",
    "configuration"    => {
      "postgresql"          => {
        "max_connections"            => 1500,
        "log_min_duration_statement" => 500
      },
      "oc_id"               => {},
      "opscode_erchef"      => {
        "depsolver_worker_count" => 4,
        "depsolver_timeout"      => 120000,
        "db_pool_size"           => 100
      },
      "oc_bifrost"          => {
        "db_pool_size" => 100
      },
      "opscode_certificate" => {
        "num_workers"                 => 4,
        "num_certificates_per_worker" => 1000
      },
      "oc_chef_authz"       => {
        "http_init_count" => 150,
        "http_max_count"  => 150
      }
    }
  },
  "supermarket" => {
    "version" => "latest",
    "prereleases"      => false,
    "nightlies"        => false,
    "package_file"     => nil,
    "package_checksum" => nil,
    "api_fqdn"         => "js4",
    "configuration"    => {
      "postgresql"          => {
        "max_connections"            => 1500,
        "log_min_duration_statement" => 500
      },
      "oc_id"               => {},
      "opscode_erchef"      => {
        "depsolver_worker_count" => 4,
        "depsolver_timeout"      => 120000,
        "db_pool_size"           => 100
      },
      "oc_bifrost"          => {
        "db_pool_size" => 100
      },
      "opscode_certificate" => {
        "num_workers"                 => 4,
        "num_certificates_per_worker" => 1000
      },
      "oc_chef_authz"       => {
        "http_init_count" => 150,
        "http_max_count"  => 150
      }
    }
  },
  "delivery" => {
    "version" => "latest",
    "prereleases"      => false,
    "nightlies"        => false,
    "package_file"     => nil,
    "package_checksum" => nil,
    "api_fqdn"         => "js4",
    "configuration"    => {
      "postgresql"          => {
        "max_connections"            => 1500,
        "log_min_duration_statement" => 500
      },
      "oc_id"               => {},
      "opscode_erchef"      => {
        "depsolver_worker_count" => 4,
        "depsolver_timeout"      => 120000,
        "db_pool_size"           => 100
      },
      "oc_bifrost"          => {
        "db_pool_size" => 100
      },
      "opscode_certificate" => {
        "num_workers"                 => 4,
        "num_certificates_per_worker" => 1000
      },
      "oc_chef_authz"       => {
        "http_init_count" => 150,
        "http_max_count"  => 150
      }
    }
  },
  "driver"          => {
    "name"            => "vagrant",
    "machine_options" => {
      "vagrant_config" => {
        "machine" => "centos6"
      }
    }
  },
  "machine_options" => {
    "backend"     => {
      "vagrant_config" => {
        "machine" => "backend"
      }
    },
    "frontend"    => {
      "vagrant_config" => {
        "machine" => "frontend"
      }
    },
    "analytics"   => {
      "vagrant_config" => {
        "machine" => "analytics"
      }
    },
    "supermarket" => {
      "vagrant_config" => {
        "machine" => "supermarket"
      }
    }
  },
  "nodes"           => [
    {
      "node_name"         => "backend1",
      "service"           => "chef_server",
      "fqdn"              => "backend1.ubuntu.vagrant",
      "ipaddress"         => "33.33.33.21",
      "cluster_ipaddress" => "33.33.34.5",
      "role"              => "backend",
      "bootstrap"         => true
    },
    {
      "node_name"         => "backend2",
      "service"           => "chef_server",
      "fqdn"              => "backend1.ubuntu.vagrant",
      "ipaddress"         => "33.33.33.31",
      "cluster_ipaddress" => "33.33.34.4",
      "role"              => "backend",
      "bootstrap"         => false
    },
    {
      "node_name" => "frontend1",
      "service"   => "chef_server",
      "fqdn"      => "frontend1.ubuntu.vagrant",
      "ipaddress" => "33.33.33.22",
      "role"      => "frontend",
      "bootstrap" => false
    },
    {
      "node_name" => "frontend2",
      "service"   => "chef_server",
      "fqdn"      => "frontend2.ubuntu.vagrant",
      "ipaddress" => "33.33.33.23",
      "role"      => "frontend",
      "bootstrap" => false
    },
    {
      "node_name" => "frontend3",
      "service"   => "chef_server",
      "fqdn"      => "frontend3.ubuntu.vagrant",
      "ipaddress" => "33.33.33.24",
      "role"      => "frontend",
      "bootstrap" => false
    },
    {
      "node_name" => "analytics1",
      "service"   => "analytics",
      "fqdn"      => "analytics.ubuntu.vagrant",
      "ipaddress" => "33.33.33.25",
      "role"      => "analytics",
      "bootstrap" => false
    },
    {
      "node_name" => "supermarket1",
      "service"   => "supermarket",
      "fqdn"      => "supermarket.ubuntu.vagrant",
      "ipaddress" => "33.33.33.26",
      "role"      => "supermarket",
      "bootstrap" => false
    },
    {
      "node_name" => "delivery-server1",
      "service"   => "delivery",
      "fqdn"      => "delivery-server1.ubuntu.vagrant",
      "ipaddress" => "33.33.33.27",
      "role"      => "delivery_server",
      "bootstrap" => false
    },
    {
      "node_name" => "delivery-build1",
      "service"   => "delivery",
      "fqdn"      => "delivery-build1.ubuntu.vagrant",
      "ipaddress" => "33.33.33.28",
      "role"      => "delivery_build",
      "bootstrap" => false
    },
    {
      "node_name" => "delivery-build2",
      "service"   => "delivery",
      "fqdn"      => "delivery-build2.ubuntu.vagrant",
      "ipaddress" => "33.33.33.23",
      "role"      => "delivery_build",
      "bootstrap" => false
    }
  ]
}
