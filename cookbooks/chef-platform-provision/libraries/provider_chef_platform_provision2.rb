# require 'cheffish'
# require 'chef/provisioning'
# require 'chef/provider/lwrp_base'
# require 'chef/provider/chef_node'
# # require 'chef/knife/node_presenter'
# require 'openssl'
# require_relative 'topo_helper'
# require 'yaml'
# class Chef
#   class Provider
#     class ChefPlatformProvisiontwo < Chef::Provider::LWRPBase
#       # use_inline_resources if defined?(use_inline_resources)

#       def whyrun_supported?
#         true
#       end

#       def action_handler
#         @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
#       end
#       def action_handler=(value)
#         @action_handler = value
#       end


#       # Register What platfrom_spec data we have at this point.
#       # This will be used by the the ready action to determine state.
#       action :allocate do
#         # puts "MACINE_OPTS"
#         # puts "MACINE_OPTS"
#         # puts "MACINE_OPTS"
#         # puts "MACINE_OPTS"
#         # # topo_chef.merged_topology.each do |nodename, config|
#         # #   puts "NODENAME: #{nodename}"
#         # #   # pp config.to_yaml

#         # #   file "#{Chef::Config[:chef_repo_path]}/#{nodename}_machine_options_config.yml" do
#         # #     content config.to_yaml
#         # #     action :create
#         # #   end
#         # # #   # pp opts.to_yaml
#         # # pp platform_attrs
#         # #   opts = {}
#         # #   opts[nodename] = machine_options_for_provider(nodename, config)
#         # #   file "#{Chef::Config[:chef_repo_path]}/#{nodename}_machine_options.yml" do
#         # #     content opts.to_yaml
#         # #     action :create
#         # #   end
#         # omnibus = JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'omnibus_private_chef.rb')))
#         # file "#{Chef::Config[:chef_repo_path]}/omnibus_private_chef.yml" do
#         #   content omnibus.to_yaml
#         #   action :create
#         # end
#         # # pp "MACHINE_OPtiONS FOR #{nodename}"
#         # # pp "MACHINE_OPtiONS FOR #{nodename}"
#         # # pp "MACHINE_OPtiONS FOR #{nodename}"
#         # # end
#         # puts "MACINE_OPTS"
#         # puts "MACINE_OPTS"
#         # puts "MACINE_OPTS"
#         # # datahash = new_platform_spec.data
#         # # puts datahash.class

#         # # registry_data_json = JSON.parse(datahash.to_json)
#         # # puts registry_data_json.class
#         # # puts "JSON"
#         # # puts "JSON"

#         # # file "#{Chef::Config[:chef_repo_path]}/attrsout.json" do
#         # #   content JSON.pretty_generate(registry_data_json)
#         # #   action :create
#         # # end


#         # # registry_data_json = JSON.parse(datahash.to_json)
#         # # file "#{Chef::Config[:chef_repo_path]}/attrsout.json" do
#         # #   content JSON.pretty_generate(registry_data_json)
#         # #   action :create
#         # # end
#         # # puts "JSON"
#         # # puts "JSON"
#         # # puts "JSON"
#         # # pp ::JSON.pretty_generate(registry_data_json)
#         # # puts "JSON"
#         # # puts "JSON"
#         # # # puts datahash.class
#         # # puts "JSON"

#         # # machine_batch 'allocate_all' do
#         # #   action [:allocate]
#         # #   # Base install on all
#         # #   topo_chef.merged_topology.each do |nodename, config|
#         # #     machine nodename do
#         # #       machine_options machine_options_for_provider(nodename, config)
#         # #       attribute 'private-chef', private_chef_attrs
#         # #       attribute 'root_ssh', platform_ssh_keys
#         # #       attribute 'osc-install', osc_install?
#         # #       attribute 'osc-upgrade', osc_upgrade?
#         # #       attributes harness_attrs
#         # #     end
#         # #   end
#         # #   only_if { new_node?(nodename) }
#         # # end
#       end
#       attr_reader :new_platform_spec, :current_platform_spec, :platform_attrs, :chef_platform_harness_attrs

#       def load_current_resource

#       end

#       action :ready do
#         #        if (!platform_spec.ready? ||
#         #            platform_spec.toplology_changed? ||
#         #            platform_spec.base_updated?)
#         # action_allocate
#         machine_batch 'ready_all' do
#           action [:ready]
#           # Base install on all
#           platform_spec.nodes.each do |server|
#             machine node_name_for(server) do
#               machine_options machine_options_for(server)
#               attributes attributes_for(server)
#               not_if { not_if_for(server) }
#               converge true
#             end
#           end
#           # only_if { new_node?(nodename) }
#         end
#         #       else
#         #         new_resource.updated_by_last_action?(false)
#         #       end
#       end


#       action :bootstrap do
#         #        if platform_spec.run_bootstrap?
#         # action_ready
#         chef_server "bootstrap_backend_{platform_spec.policy_group}" do
#           action action_for(platform_spec.bootstrap_backend)
#           config chef_server_configurables


#           config
#         end
#         #        else
#         #          new_resource.updated_by_last_action?(false)
#         #        end
#         # end

#         action :deploy do
#           machine_batch 'deploy_remaining' do
#             action [:converge]
#             topo_chef.merged_topology.each do |nodename, config|
#               # skip the bootstrap node in this batch
#               next if nodename == topo_chef.bootstrap_node_name
#               machine nodename do
#                 machine_options machine_options_for_provider(nodename, config)
#                 attribute 'private-chef', private_chef_attrs
#                 attribute 'root_ssh', platform_ssh_keys
#                 attribute 'osc-install', osc_install?
#                 attribute 'osc-upgrade', osc_upgrade?
#                 attributes harness_attrs
#                 recipe 'private-chef::hostname'
#                 recipe 'private-chef::hostsfile'
#                 recipe 'private-chef::rhel'
#                 recipe 'private-chef::provision'
#                 recipe 'private-chef::drbd' if topo_chef.is_backend?(nodename)
#                 recipe 'private-chef::provision_phase2'
#                 recipe 'private-chef::reporting' if harness_attrs['reporting_package']
#                 recipe 'private-chef::manage' if (harness_attrs['manage_package'] &&
#                                                   topo_chef.is_frontend?(nodename))
#                 recipe 'private-chef::pushy' if harness_attrs['pushy_package']
#                 recipe 'private-chef::tools'
#                 converge true
#                 # not_if { server_bootstrap_node?(nodename) }
#               end
#             end
#           end
#         end

#         action :destroy_all do
#           machine_batch 'destroy_all' do
#             action [:destroy]
#             topo_chef.merged_topology.each do |nodename, config|
#               machine nodename do
#                 machine_options machine_options_for_provider(nodename, config)
#               end
#             end
#           end
#         end

#         action :converge do
#           action_allocate
#         end

#         attr_reader :new_platform_spec, :current_platform_spec, :platform_attrs, :chef_platform_harness_attrs

#         def load_current_resource
#           @platform_spec = Provisioner::Platform::ChefPlatformSpec.get_or_empty(new_resource, new_resource.chef_server)
#           @chef_server_configurables
#           # @platform_attrs = new_resource.policy_default_attributes['chef_platform']
#           puts "ALLOCATE"
#           puts "ALLOCATE"
#           puts "ALLOCATE"
#           pp platform_topology
#           puts "ALLOCATE"
#           puts "ALLOCATE"
#           puts "ALLOCATE"
#           # require "awesome_print"
#           # ap platform_attrs, options = {
#           #   :indent => -2,
#           #   :index => false,
#           #   :color => {
#           #     :hash  => :pale,
#           #     :class => :white
#           #   }
#           # }


#           platform_attrs.each do |k,v|
#             puts k
#           end

#           # pp @chef_environment
#           # pp @chef_server
#           # pp @driver
#           # pp @machine_options
#           # puts "ALLOCATE"
#           # puts "ALLOCATE"
#           # puts "ALLOCATE"
#           # pp run_context.cheffish.inspect
#           # pp run_context.node[:name]
#           # run_context.resource_collection.each do |k,v|
#           #   puts k
#           # end
#           # puts "ALLOCATE"
#           # puts "ALLOCATE"
#           # pp new_resource.chef_platform_harness_attrs
#           # puts "ALLOCATE"
#           # node_driver = Chef::Provider::ChefNode.new(new_resource, run_context)
#           # node_driver.load_current_resource
#           # json = node_driver.new_json
#           # puts "JSON"
#           # puts "JSON"
#           # puts "JSON"
#           # pp json
#           # puts "JSON"
#           # puts new_resource.name
#           # puts new_resource.policy_group
#           # puts "JSON"
#           # puts "JSON"
#           # json['normal']['chef_provisioning'] = node_driver.current_json['normal']['chef_provisioning'] || {}
#           # json['normal']['chef_provisioning']['provisioner'] ||= {}
#           # json['normal']['chef_provisioning']['provisioner'] = new_resource.platform_attributes
#           # spec_name = "#{new_resource.name}"
#           # @new_platform_spec = chef_platform_spec_data.get_or_new(new_resource.policy_group.to_sym,
#           # new_resource.name,)
#           # pp action_handler
#           # @machine_spec.save_data(new_resource.policy_group.to_sym,
#           #                         new_resource.name,
#           #                         new_resource.platform_attributes,
#           #                         action_handler)

#           # puts "machine_spec"
#           # pp @machine_spec.instance_variables.managed_entry_store
#           # pp @machine_spec.data
#           #   @new_platform_spec = Chef::Provisioning::ChefPlatform::ChefChefPlatformSpec.get_new(new_resource, new_resource.chef_server)
#           #   @current_platform_spec = Chef::Provisioning::ChefPlatform::ChefChefPlatformSpec.get_current_or_empty(new_resource, new_resource.chef_server)
#         end

#         # def chef_platform_spec_data
#         #   @chef_platform_spec_data ||= Provisioner.chef_platform_spec(new_resource.chef_server)
#         # end

#         def bootstrap_backend
#           @bootstrap_backend ||= begin
#             bootstrap_node = {}
#             if (platform_spec.topology == "standalone")
#               bootstrap_node = platform_spec.standalone_node
#             else
#               platform_spec.nodes.each do |node_data|
#                 bootstrap_node.merge!(element) if ( node_data.kind_of?(Hash) &&
#                                                     node_data['product'] == 'chef_server' &&
#                                                     node_data['role'] == 'backend' &&
#                                                     node_data['boostrap'])
#               end
#             end
#             bootstrap_node
#           end
#         end


#         def topo_chef
#           @topo_chef ||= ::TopoHelper.new(ec_config: platform_topology, include_layers: use_ec_layers)
#         end

#         def ecm_top
#           topo_chef
#         end

#         # def entry_store_name(policy_group = new_resource.policy_group)
#         #   @entry_store_name ||= "#{policy_group}_chef_platform"
#         # end

#         def private_chef_attrs
#           platform_attrs['private-chef']
#         end

#         def analytics_attrs
#           platform_attrs['analytics']
#         end

#         def platform_ssh_keys
#           platform_attrs['root_ssh']
#         end

#         #       {
#         #   :fqdn => server['fqdn'],
#         #   :ipaddress => server['ipaddress'],
#         #   :bootstrap => server['chef-server-cluster']['bootstrap']['enable'],
#         #   :role => server['chef-server-cluster']['role']
#         # }

#         def osc_install?
#           platform_attrs['osc-install']
#         end

#         def osc_upgrade?
#           platform_attrs['osc-upgrade']
#         end

#         def cloud_attrs
#           platform_attrs['cloud']
#         end

#         def provisioning_driver
#           cloud_attrs['provider']
#         end

#         def harness_attrs
#           platform_attrs['harness']
#         end

#         def platform_topology
#           harness_attrs['vm_config']
#         end

#         def use_ec_layers
#           %w(frontends backends standalones)
#         end

#         def machine_options_for_provider(nodename, config)
#           case provisioning_driver
#           when 'ec2'
#             ::Ec2ConfigHelper.generate_config(nodename, config, platform_attrs)
#           when 'vagrant'
#             pp
#             machine_ops = ::VagrantConfigHelper.generate_config(nodename, config, platform_attrs)
#             puts "vagrant_machine_opts"
#             puts "vagrant_machine_opts"
#             pp machine_ops
#             puts "vagrant_machine_opts"
#             puts "vagrant_machine_opts"
#             machine_ops
#           else
#             raise "No provider set!"
#           end
#         end

#       end
#     end
#   end
