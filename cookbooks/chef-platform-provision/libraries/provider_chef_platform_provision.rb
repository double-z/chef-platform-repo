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
        if all_nodes_ready?
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
          puts "READY!"
        else
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
          puts "NOT READY!"
        end

        b = machine_batch 'machine_batch_ready_all' do
          action :nothing
          new_platform_spec.all_nodes.each do |server|
            machine server['node_name'] do
              driver "vagrant"
              machine_options vagrant_machine_opts_for(server)
              converge true
            end
          end
        end

        b.run_action(:converge)
        apd("ready b.updated_by_last_action?.to_s", true_false_to_s(b.updated_by_last_action?))

        ruby_block "ready_action_node_sync" do
          block do
            node_data = []
            b.machines.each do |bm|
              node_driver = Chef::Provider::ChefNode.new(bm, run_context)
              node_driver.load_current_resource
              json = ::Provisioner.deep_hashify(node_driver.new_json)
              if (json["automatic"] &&
                  json["automatic"]["network"] &&
                  json["automatic"]["network"]["interfaces"])

                new_platform_spec.all_nodes.each do |_server|
                  server = ::Provisioner.deep_hashify(_server)
                  node_data << get_node_with_ip(server, json)
                  # if ( !server['ipaddress'] && (bm.name == server['node_name']))
                  #   puts "bm.name: #{bm.name}"
                  #   puts "server.name: #{server['node_name']}"
                  #   json["automatic"]["network"]["interfaces"]["#{server['interface']}"]["addresses"].each do |k,v|
                  #     new_data = ::Provisioner.deep_hashify(server)
                  #     new_data['ipaddress'] = k.to_s if (v["family"] == "inet")
                  #     node_data << new_data if (new_data['ipaddress'] && (v["family"] == "inet"))
                  #   end
                  # end
                end

              end
            end
            # new_platform_spec.last_action = "ready"
            # new_platform_spec.last_action_at = Time.now
            new_platform_spec.nodes = node_data if !node_data.empty?
            new_platform_spec.save_data_bag(action_handler)
            apd("node_data", new_platform_spec.all_nodes)
          end
          action :nothing unless b.updated_by_last_action?
          notifies :_test_ready, "chef_platform_provision[prod]", :immediately
        end
      end

      action :_test_ready do
        ruby_block 'run_test_ready' do
          block do
            apd("ruby_block_all_nodes_test_ready", new_platform_spec.all_nodes)
          end
          action :run
          notifies :generate_config, "chef_platform_provision[prod]", :immediately
        end
        if all_nodes_ready?
          puts "TREADY!"
          puts "TREADY!"
          puts "TREADY!"
          puts "TREADY!"
          puts "TREADY!"
        else
          puts "TNOT READY!"
          puts "TNOT READY!"
          puts "TNOT READY!"
          puts "TNOT READY!"
          puts "TNOT READY!"
        end
      end

      action :generate_config do
        server_rb_file_path = ::File.join(Chef::Config[:chef_repo_path], "chef-server.rb")
        r = Chef::Resource::Template.new(server_rb_file_path, run_context)
        r.source("chef-server.rb.erb")
        r.mode("0644")
        r.cookbook("chef-platform-provision")
        r.variables(
          :chef_servers => new_platform_spec.chef_server_nodes,
          :chef_server_config => new_platform_spec.chef_server_config,
          :chef_server_data => new_platform_spec.chef_server_data
        )

        server_rb_file_path = ::File.join(Chef::Config[:chef_repo_path], "chef-server2.rb")
        rr = Chef::Resource::Template.new(server_rb_file_path, run_context)
        rr.source("chef-server.rb.erb")
        rr.mode("0644")
        rr.cookbook("chef-platform-provision")
        rr.variables(
          :chef_servers => new_platform_spec.chef_server_nodes,
          :chef_server_config => new_platform_spec.chef_server_config,
          :chef_server_data => new_platform_spec.chef_server_data
        )

        r.run_action(:create)
        rr.run_action(:create)

        ruby_block 'generate_configs' do
          block do
            # Mostly for Singular Notificationer
            # Do Sanity Check/Validation/Etc here
          end
          action :nothing unless (r.updated_by_last_action? || rr.updated_by_last_action?)
          notifies :push_config, "chef_platform_provision[prod]", :immediately
        end

      end

      action :push_config do
        machine_batch 'do_push_config' do
          action :converge
          new_platform_spec.all_nodes.each do |server|
            machine server['node_name'] do
              driver "vagrant"
              machine_options vagrant_machine_opts_for(server)
              files(
                '/etc/opscode/chef-server.rb' => ::File.join(Chef::Config[:chef_repo_path], "chef-server.rb"),
                '/etc/opscode/chef-server2.rb' => ::File.join(Chef::Config[:chef_repo_path], "chef-server2.rb")
              )
              # converge true
            end
          end
        end
      end

      action :bootstrap do
        ruby_block 'bootstrap_action' do
          block do
            puts "BOOTSTRAP"
            # current_platform_spec.all_nodes.each do |server|
            #   puts "  machine #{server['node_name']} do"
            #   puts "    machine_options machine_options_for(#{apl(vagrant_machine_opts_for(server))})"
            #   puts "  end"
            #   puts "end"
            # end
          end
          action :run
        end
      end

      action :deploy do

      end

      action :reconfigure do
        if should_run?
          if !all_nodes_ready?
            action_ready
          else
            action_generate_config
          end
          @new_resource.updated_by_last_action(true)
        else
          @new_resource.updated_by_last_action(false)
        end
      end

      action :destroy_all do
        bd = machine_batch 'machine_batch_ready_all' do
          action :nothing
          new_platform_spec.all_nodes.each do |server|
            machine server['node_name'] do
              driver "vagrant"
              machine_options vagrant_machine_opts_for(server)
              converge true
            end
          end
        end

        bd.run_action(:destroy)
        @new_resource.updated_by_last_action(db.updated_by_last_action?)
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

      attr_reader :chef_server, :platform_spec, :new_platform_spec, :current_platform_spec, :rollback_platform_spec

      def load_current_resource
        apd("LOAD_CURRENT_RESOURCE", new_resource.init_time)
        @chef_server = new_resource.chef_server
        @new_platform_spec = Provisioner::ChefPlatformSpec.new_spec(new_resource.policy_group,
                                                                    ::Provisioner.deep_hashify(new_resource.platform_data))
        @current_platform_spec = Provisioner::ChefPlatformSpec.current_spec(new_resource.policy_group)
        log_all_data if new_resource.log_all
        apd("new_platform_nodes", @new_platform_spec.get)
        apd("current_platform_nodes", @current_platform_spec.nodes)
      end

      def get_node_with_ip(server, json)
        # if ( !server['ipaddress'] && (bm.name == server['node_name']))
        #   puts "bm.name: #{bm.name}"
        #   puts "server.name: #{server['node_name']}"
        #   json["automatic"]["network"]["interfaces"]["#{server['interface']}"]["addresses"].each do |k,v|
        #     new_data = ::Provisioner.deep_hashify(server)
        #     new_data['ipaddress'] = k.to_s if (v["family"] == "inet")
        #     node_data << new_data if (new_data['ipaddress'] && (v["family"] == "inet"))
        #   end
        # end
      end

      def all_nodes_ready?
        nodes_ready = current_platform_spec.nodes
        if nodes_ready.nil?
          false
        else
          true
        end
      end

      def true_false_to_s(tf)
        if tf
          "true"
        else
          "false"
        end
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
