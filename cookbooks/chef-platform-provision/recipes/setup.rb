# #
# # Cookbook Name:: chef-platform-provision
# # Recipe:: setup
# #
# # Copyright (c) 2015 Zack Zondlo, All Rights Reserved.

# ##
# # The Setup phase is responsible for Base Config including:
# #
# # - installing necessary/desired repositories packages
# # - disabling/configuring system level settings i.e firewall, ntp, sysctl
# # - OS specific setup
# # - base security
# # - chef-server etc. specific reqs i.e hostname sanity
# # - writing out local-attributes of interest to neighbors i.e interface ip's etc
# #   into json file in chef cache

# machine_batch :setup do
#   machine topology.bootstrap_backend_or_standalone_machine_name do
#     action :converge
#     attribute %w[ chef-platform server bootstrap enable ], true
#     attribute %w[ chef-platform server role ], topology.backend_or_standalone
#     attribute %w[ provision phase ], 'setup'
#   end

#   machine topology.secondary_backend_machine_name do
#     action :converge
#     attribute %w[ chef-platform server bootstrap enable ], topology.is_bootstrap_node?
#     attribute %w[ chef-platform server role ], 'backend'
#     attribute %w[ provision phase ], 'setup'    
#     only_if do
#       topology.is_ha?
#     end
#   end

#   topology.frontends.each do |fe|
#     machine topology.frontend_machine_name(fe) do
#       action :converge
#       attribute %w[ provision phase ], 'setup'
#     end
#   end if !topology.is_standlone?

# end

# ##
# # This should probably be notified by above but anyway...
# #
# # Now we get the configs and generate a global topology config
# # This will be something like this for each node:
# #
# # [
# #   {
# #     :fqdn => server['fqdn'],
# #     :ipaddress => server['ipaddress'],
# #     :bootstrap => server['chef-platform']['server']['bootstrap']['enable'],
# #     :role => server['chef-platform']['server']['role']
# #   }
# #  ]

# download_node_configs 'setup' do
# 	machine_names topology.machine_names
# end
