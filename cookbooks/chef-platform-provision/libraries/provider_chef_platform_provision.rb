require 'cheffish'
require 'chef/provisioning'
require 'chef/provisioning/vagrant_driver'
require 'chef/provisioning/ssh_driver'
require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
require 'openssl'
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

        b = machine_batch 'machine_batch_ready_all' do
          action :nothing
          new_platform_spec.all_nodes.each do |server|
            machine server['node_name'] do
              driver "ssh"
              machine_options machine_opts_for(server)
              converge true
            end
          end
        end
        b.run_action(:converge)

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
                  if (bm.name.to_s == server['node_name'])
                    json["automatic"]["network"]["interfaces"]["#{server['interface']}"]["addresses"].each do |k,v|
                      new_data = ::Provisioner.deep_hashify(server)
                      new_data['ipaddress'] = k.to_s if (v["family"] == "inet")
                      node_data << new_data if (new_data['ipaddress'] && (v["family"] == "inet"))
                    end
                  end
                end

              end
            end
            # new_platform_spec.last_action = "ready"
            # new_platform_spec.last_action_at = Time.now
            new_platform_spec.nodes = node_data if !node_data.empty?
            new_platform_spec.save_data_bag(action_handler)
          end
          action :nothing unless b.updated_by_last_action?
          notifies :_test_ready, "chef_platform_provision[prod]", :immediately
        end
      end

      action :_test_ready do
        ruby_block 'run_test_ready' do
          block do
            # apd("ruby_block_all_nodes_test_ready", new_platform_spec.all_nodes)
          end
          action :run
          notifies :generate_config, "chef_platform_provision[prod]", :immediately
        end
      end

      action :generate_config do

        ruby_block 'generate_configs' do
          block do
            chef_server_rb_template.run_action(:create)
            analytics_rb_template.run_action(:create)
            new_platform_spec.save_data_bag(action_handler)

            # Also for Singular Notificationer
            # Do Sanity Check/Validation etc. here
          end
          notifies :_push_config, "chef_platform_provision[prod]", :immediately
        end

      end

      action :_push_config do
        machine_batch 'do_push_config' do
          action :converge
          new_platform_spec.all_nodes.each do |server|
            machine server['node_name'] do
              driver "ssh"
              machine_options machine_opts_for(server)
              files(
                '/etc/opscode/chef-server.rb' => local_chef_server_rb_path,
                '/etc/opscode-analytics/analytics.rb' => local_analytics_rb_path
              )
            end
          end
        end
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
        mbd = machine_batch 'machine_batch_ready_all' do
          action :nothing
          new_platform_spec.all_nodes.each do |server|
            machine server['node_name'] do
              driver "vagrant"
              machine_options vagrant_machine_opts_for(server)
              converge true
            end
          end
        end

        mbd.run_action(:destroy)

        chef_server_rb_template.run_action(:delete) if mbd.updated_by_last_action?
        analytics_rb_template.run_action(:delete) if mbd.updated_by_last_action?
        new_platform_spec.delete_data_bag_item_entry(action_handler) if mbd.updated_by_last_action?
        @new_resource.updated_by_last_action(mbd.updated_by_last_action?)
      end

      def machine_opts_for(server)
        case new_platform_spec.driver_name
        when "ssh"
          ssh_machine_opts_for(server)
        when "vagrant"
          vagrant_machine_opts_for(server)
        end
      end

      def vagrant_machine_opts_for(server)
        machine_ops = ::VagrantConfigHelper.generate_config(server)
        machine_ops
      end

      def ssh_machine_opts_for(server)
        machine_ops = ::SshConfigHelper.generate_config(server)
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
        apd("Resource Init Time", new_resource.init_time)
        @chef_server = new_resource.chef_server
        @current_platform_spec = Provisioner::ChefPlatformSpec.current_spec(new_resource.policy_group)
        @new_platform_spec = Provisioner::ChefPlatformSpec.new_spec(new_resource.policy_group,
                                                                    ::Provisioner.deep_hashify(new_resource.platform_data))
        apd("driver", new_platform_spec.driver_name)
        new_platform_spec.nodes = all_ready_nodes if all_nodes_ready?
        log_all_data if new_resource.log_all
      end

      def analytics_rb_template
        analytics_rb_file_path = ::File.join(Chef::Config[:chef_repo_path], "analytics.rb")
        arbt = Chef::Resource::Template.new(analytics_rb_file_path, run_context)
        arbt.source("analytics.rb.erb")
        arbt.mode("0644")
        arbt.cookbook("chef-platform-provision")
        arbt.variables(
          :chef_analytics => new_platform_spec.analytics_data
        )
        arbt
      end

      def chef_server_rb_template
        server_rb_file_path = ::File.join(Chef::Config[:chef_repo_path], "chef-server.rb")
        csrt = Chef::Resource::Template.new(server_rb_file_path, run_context)
        csrt.source("chef-server.rb.erb")
        csrt.mode("0644")
        csrt.cookbook("chef-platform-provision")
        csrt.variables(
          :chef_servers => new_platform_spec.chef_server_nodes,
          :chef_server_config => new_platform_spec.chef_server_config,
          :chef_server_data => new_platform_spec.chef_server_data
        )
        csrt
      end

      def get_node_with_ip(server, json)
        if ( !server['ipaddress'] && (bm.name == server['node_name']))
          puts "bm.name: #{bm.name}"
          puts "server.name: #{server['node_name']}"
          json["automatic"]["network"]["interfaces"]["#{server['interface']}"]["addresses"].each do |k,v|
            new_data = ::Provisioner.deep_hashify(server)
            new_data['ipaddress'] = k.to_s if (v["family"] == "inet")
            return_data = (new_data['ipaddress'] && (v["family"] == "inet"))
            return_data
          end
        end
      end

      def should_run?
        val = false
        val = (!all_nodes_ready? ||
               config_updated?)
        val
      end

      def all_nodes_ready?
        nodes_ready = current_platform_spec.nodes
        if nodes_ready.nil?
          false
        else
          true
        end
      end

      def all_ready_nodes
        current_platform_spec.nodes
      end

      def local_analytics_rb_path
        ::File.join(Chef::Config[:chef_repo_path], "analytics.rb")
      end

      def local_chef_server_rb_path
        ::File.join(Chef::Config[:chef_repo_path], "chef-server.rb")
      end

      ####
      #
      # Begin Check Configs
      #

      # Check all configs
      def config_updated?
        val = (chef_server_config_updated? ||
               analytics_config_updated?)
      end

      # Check chef_server
      def chef_server_config_updated?
        if !::File.exists?(local_chef_server_rb_path)
          true
        else
          current_hash = current_platform_spec.chef_server_config
          new_hash = new_platform_spec.chef_server_config
          val = current_hash.eql?(new_hash)
          ret_val = val ? false : true
          ret_val
        end
      end

      # Check analytics
      def analytics_config_updated?
        if !::File.exists?(local_analytics_rb_path)
          true
        else
          current_hash = current_platform_spec.analytics_configuration
          new_hash = new_platform_spec.analytics_configuration
          val = current_hash.eql?(new_hash)
          ret_val = val ? false : true
          ret_val
        end
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
        ::Provisioner.log_all_data(new_platform_spec)
      end

      def apd(name, data)
        ::Provisioner.apd(name, data)
      end

      def true_false_to_s(tf)
        ::Provisioner.true_false_to_s(tf)
      end

    end
  end
end
