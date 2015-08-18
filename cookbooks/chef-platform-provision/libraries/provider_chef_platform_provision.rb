require 'cheffish'
require 'chef/provisioning'
require 'chef/provisioning/vagrant_driver'
require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
# require 'chef/knife/node_presenter'
require 'openssl'
# require_relative 'topo_helper'
require_relative 'topo_helper'
require 'yaml'
require "awesome_print"

class Chef
  class Provider
    class ChefPlatformProvision < Chef::Provider::LWRPBase
      # use_inline_resources # if defined?(use_inline_resources)

      def whyrun_supported?
        true
      end

      def action_handler
        @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
      end

      def action_handler=(value)
        @action_handler = value
      end

      # Register What platfrom_spec data we have at this point.
      # This will be used by the the ready action to determine state.
      action :allocate do

        # new_platform_spec.status = "allocated"
        # new_platform_spec.allocated_at = Time.now
      end

      action :ready do
        # action_allocate if (!platform_spec.ready? ||
        #            platform_spec.toplology_changed? ||
        #            platform_spec.base_updated?)
        # 
        #

        b = machine_batch 'ready_all' do
          action :converge
          # action :ready
          # action :allocate
          # action :destroy
          new_platform_spec.all_nodes.each do |server|
            machine server['node_name'] do
              driver "vagrant"
              machine_options vagrant_machine_opts_for(server)
              converge true
            end
          end
          notifies :run, 'ruby_block[ready_action_for]', :immediately
        end

        ruby_block "ready_action_for" do
          block do
            node_data = []
            b.machines.each do |bm|
              node_driver = Chef::Provider::ChefNode.new(bm, run_context)
              node_driver.load_current_resource
              json = node_driver.new_json

              if (json["automatic"] &&
                  json["automatic"]["network"] &&
                  json["automatic"]["network"]["interfaces"])

                new_platform_spec.all_nodes.each do |_server|
                  server = ::Provisioner.deep_hashify(_server)
                  puts "IF:"
                  apd("server", server)
                  puts server["interface"]
                  # server.each do |kk, vv|
                  #   puts "kk =#{kk} vv=#{vv}"
                  # end
                  puts "IF:"
                  puts "json['automatic']['network']['interfaces'][#{server['interface']}]['addresses']" #.each do |k,v|
                  json["automatic"]["network"]["interfaces"]["eth1"]["addresses"].each do |k,v|
                    if (bm.name == server['node_name'])
                      new_data = ::Provisioner.deep_hashify(server)
                      new_data['ipaddress'] = k.to_s if (v["family"] == "inet") # ||
                      node_data << new_data if new_data['ipaddress']
                    end
                  end
                end

              end

            end
            new_platform_spec.nodes = node_data
            new_platform_spec.save_data_bag(action_handler)
            apd("node_data", new_platform_spec.all_nodes)
          end
          action :nothing
          notifies :bootstrap, "chef_platform_provision[prod]", :immediately
        end
      end

      action :bootstrap do
        ruby_block 'bootstrap_action' do
          block do
            current_platform_spec.all_nodes.each do |server|
              puts "  machine #{server['node_name']} do"
              puts "    machine_options machine_options_for(#{apl(vagrant_machine_opts_for(server))})"
              puts "  end"
              puts "end"
            end
          end
          action :run
        end
      end

      action :deploy do

      end

      action :destroy_all do

      end

      action :converge do
        action_allocate
      end

      def vagrant_machine_opts_for(server)
        machine_ops = ::VagrantConfigHelper.generate_config(server)
        machine_ops
      end

      def machine_options_for(server)
        configs = []

        configs << {
          :convergence_options =>
          [ :chef_server,
            :allow_overwrite_keys,
            :source_key, :source_key_path, :source_key_pass_phrase,
            :private_key_options,
            :ohai_hints,
            :public_key_path, :public_key_format,
            :admin, :validator,
            :chef_config
          ].inject({}) do |result, key|
            result[key] = new_resource.send(key)
            result
          end
        }

        configs << node_machine_options(server) if has_node_machine_options?(server)
        configs << service_machine_options(server) if has_service_machine_options?(server)
        configs << driver_machine_options(server) if has_driver_machine_options?(server)
        # configs << driver.config[:machine_options] if driver.config[:machine_options]
        Cheffish::MergedConfig.new(*configs)
      end

      def attribute_data_changed?
        new_attribute_data == current_attribute_data
      end

      def should_ready_notify_chef_server()
      end

      def should_ready_notify_analytics()
      end

      def should_ready_notify_supermarket()
      end

      attr_reader :platform_spec, :new_platform_spec, :current_platform_spec, :rollback_platform_spec

      # def load_current_resource
      #   @new_platform_spec = Provisioner::ChefPlatformSpec.new_spec(new_resource.platform_data)
      #   @current_platform_spec = Provisioner::ChefPlatformSpec.current_spec(new_resource.policy_group)
      #   @rollback_platform_spec = Provisioner::ChefPlatformSpec.rollback_spec(new_resource.policy_group)
      # end

      def load_current_resource
        # @platform_spec = Provisioner::ChefPlatformSpec.new(new_resource.platform_data)
        @new_platform_spec = Provisioner::ChefPlatformSpec.new_spec(new_resource.platform_data)
        @current_platform_spec = Provisioner::ChefPlatformSpec.current_spec(new_resource.policy_group)
        log_all_data if new_resource.log_all
        # pp run_context.resource_collection.inspect
        # apd("current_platform_nodes", @current_platform_spec.all_nodes)
        # apd("new_platform_nodes", @new_platform_spec.all_nodes)
        apd("current_platform_nodes", @current_platform_spec.get)
        apd("new_platform_nodes", @new_platform_spec.get)
        new_platform_spec.save_data_bag(action_handler) # if nodes_updated?
      end

      ####
      #
      # Begin Check Configs
      #

      # Check chef_server
      def chef_server_config_updated?
        current_hash = current_platform_spec.chef_server_config
        new_hash = new_platform_spec.chef_server_config
        val = current_hash.eql?(new_hash)
        ret_val = val ? false : true
        ret_val
      end

      # Check analytics
      def analytics_config_updated?
        current_hash = current_platform_spec.analytics_config
        new_hash = new_platform_spec.analytics_config
        val = current_hash.eql?(new_hash)
        ret_val = val ? false : true
        ret_val
      end

      # Check supermarket
      def supermarket_config_updated?
        current_hash = current_platform_spec.supermarket_config
        new_hash = new_platform_spec.supermarket_config
        val = current_hash.eql?(new_hash)
        ret_val = val ? false : true
        ret_val
      end

      # Check delivery
      def delivery_config_updated?
        current_hash = current_platform_spec.delivery_config
        new_hash = new_platform_spec.delivery_config
        val = current_hash.eql?(new_hash)
        ret_val = val ? false : true
        ret_val
      end

      #
      # End Check Configs
      #
      ####

      def log_all_data
        omnibus = JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'Policyfile.lock.json'))) # new_resource.merged_platform_data.to_hash # JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'omnibus_private_chef.rb')))
        omnibuspl = omnibus['default_attributes']['chef_platform']
        file "#{Chef::Config[:chef_repo_path]}/policy_attributes.yml" do
          content omnibuspl.to_yaml
          action :create
        end

        apd("new_resource.platform_data", new_resource.platform_data)
        # apd("new_resource.policy_default_attributes", new_resource.policy_default_attributes)
        # apd("new_resource.policy_merged_attributes", new_resource.policy_merged_attributes)
        apd("all_data", new_platform_spec.get)
        apd("all_nodes", new_platform_spec.all_nodes)
        apd("chef_server_nodes", new_platform_spec.chef_server_nodes)
        apd("chef_server_frontend_nodes", new_platform_spec.chef_server_frontend_nodes)
        apd("chef_server_non_bootstrap_nodes", new_platform_spec.chef_server_non_bootstrap_nodes)
        apd("chef_server_bootstrap_backend", new_platform_spec.chef_server_bootstrap_backend)
        apd("chef_server_secondary_backend", new_platform_spec.chef_server_secondary_backend)
        apd("chef_server_config", new_platform_spec.chef_server_config)
        apd("analytics_nodes", new_platform_spec.analytics_nodes)
        apd("supermarket_nodes", new_platform_spec.supermarket_nodes)
        apd("delivery_nodes", new_platform_spec.delivery_nodes)
        apd("delivery_server_nodes", new_platform_spec.delivery_server_node)
        apd("delivery_build_nodes", new_platform_spec.delivery_build_nodes)

        log_test_if("is_chef_server?")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_chef_server?(server)
            puts "Chef Server #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Chef Server #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_bootstrap_backend?")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_bootstrap_backend?(server)
            puts "Bootstrap Backend #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Bootstrap Backend #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_secondary_backend?")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_secondary_backend?(server)
            puts "Secondary Backend #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Secondary Backend #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_backend")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_backend?(server)
            puts "Backend #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Backend #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_frontend")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_frontend?(server)
            puts "Frontend #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Frontend #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_analytics")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_analytics?(server)
            puts "Analytics #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Analytics #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_supermarket")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_supermarket?(server)
            puts "Supermarket #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Supermarket #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_delivery")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_delivery?(server)
            puts "Delivery #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Delivery #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_delivery_server")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_delivery_server?(server)
            puts "Delivery Server #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Delivery Server #{server['node_name']}"
          end
        end
        puts

        log_test_if("is_delivery_build?")
        new_platform_spec.all_nodes.each do |server|
          if new_platform_spec.is_delivery_build?(server)
            puts "Delivery Build #{server['node_name']}"
          else
            puts "#{server['node_name']} NOT Delivery Build #{server['node_name']}"
          end
        end
      end

      def apd(name, data)
        upname = name.upcase
        puts "=========================================================="
        puts
        puts "BEGIN #{upname}"
        puts
        apl(data)
        puts
        puts "END #{upname}"
        puts
        puts "=========================================================="
      end

      def apl(data)
        ap data, options = {
          :indent => -2,
          :index => false,
          :color => {
            :hash  => :pale,
            :class => :white
          }
        }
      end

      def log_test_if(name)
        puts "=========================================================="
        puts
        puts "TEST IF: #{name}"
        puts
      end

    end
  end
end
