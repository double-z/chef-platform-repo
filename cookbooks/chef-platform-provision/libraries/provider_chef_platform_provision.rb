require 'cheffish'
require 'chef/provisioning'
require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'

class Chef
  class Provider
    class ChefPlatformProvision < Chef::Provider::LWRPBase

      def action_handler
        @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
      end

      ##
      # Public Actions
      #
      # * These wil be accessible directly from recipe
      #    - reconfigure
      #    - destroy_all

      action :reconfigure do
      	puts "shoudrun #{should_run?.to_s}"
      	puts "allnodes #{all_nodes_ready?.to_s}"
      	puts "condif #{config_updated?.to_s}"

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

        mbd = machine_batch 'machine_batch_destroy_all' do
          action :nothing
          new_platform_spec.all_nodes.each do |server|
            machine server['fqdn'] do
              driver new_platform_spec.driver_name
              machine_options machine_opts_for(server)
              converge true
            end
          end
        end

        mbd.run_action(:destroy)

        chef_server_rb_template.run_action(:delete) if mbd.updated_by_last_action?
        analytics_rb_template.run_action(:delete) if mbd.updated_by_last_action?

        current_platform_spec.delete(action_handler) if mbd.updated_by_last_action?

        @new_resource.updated_by_last_action(mbd.updated_by_last_action?)
      end

      ##
      # Private Actions. Access will be restricted

      # called by reconfigure action
      action :ready do

        dg = directory platform_policy_group_cache_path do
          mode '0755'
          action :nothing
          recursive true
        end
        dcs = directory local_chef_server_cache_path do
          mode '0755'
          action :nothing
          recursive true
        end
        da = directory local_analytics_cache_path do
          mode '0755'
          action :nothing
          recursive true
        end
        dg.run_action(:create) unless ::File.exists?(platform_policy_group_cache_path)
        dcs.run_action(:create) unless ::File.exists?(local_chef_server_cache_path)
        da.run_action(:create) unless ::File.exists?(local_analytics_cache_path)

        b = machine_batch 'machine_batch_ready_all' do
          action :nothing
          new_platform_spec.all_nodes.each do |server|
            machine server['fqdn'] do
              driver new_platform_spec.driver_name
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
              json = Chef::Provisioner::Helpers.deep_hashify(node_driver.new_json)
              if (json["automatic"] &&
                  json["automatic"]["network"] &&
                  json["automatic"]["network"]["interfaces"])

                new_platform_spec.all_nodes.each do |_server|
                  server = Chef::Provisioner::Helpers.deep_hashify(_server)
                  if (bm.name.to_s == server['fqdn'])
                    json["automatic"]["network"]["interfaces"]["#{server['interface']}"]["addresses"].each do |k,v|
                      server['ipaddress'] = k.to_s if (v["family"] == "inet")
                      node_data << server if (server['ipaddress'] && (v["family"] == "inet"))
                    end
                  end
                end

              end
            end
            new_platform_spec.nodes = node_data if !node_data.empty?
            new_platform_spec.save(action_handler)
          end
          action :nothing unless b.updated_by_last_action?
          notifies :_setup, "chef_platform_provision[prod]", :immediately
        end
      end

      # will only be accessible when notified by ready
      action :_setup do
        hostsfile_template.run_action(:create)

        new_platform_spec.all_nodes.each do |server|
          machine_file "/etc/hosts" do
            local_path local_hostsfile_path
            machine server['fqdn']
            action :upload
            # action :upload if hostsfile_template.updated_by_last_action?
            # action :nothing if !hostsfile_template.updated_by_last_action?
          end
        end

        machine_batch 'do_setup' do
          action :converge
          new_platform_spec.all_nodes.each do |server|
            machine server['fqdn'] do
              attribute 'platform_action', "setup"
              attribute 'platform_node', server
              recipe "platform-node::default"
              driver new_platform_spec.driver_name
              machine_options machine_opts_for(server)
            end
          end
          notifies :_test_setup, "chef_platform_provision[prod]", :immediately
        end
      end

      # will only be accessible when notified by ready
      action :_test_setup do
        ruby_block 'run_test_setup' do
          block do
            # Do Sanity Check/Validation etc. here
            # i.e:
            # checks_failed = check_if_something_fails
            # raise "checks failed" if checks_failed
          end
          action :run
          notifies :generate_config, "chef_platform_provision[prod]", :immediately
        end
      end

      # called by reconfigure action or notified by _test_ready action
      action :generate_config do
        chef_server_rb_template.run_action(:create)
        analytics_rb_template.run_action(:create)
        run_notify_push_config = (chef_server_rb_template.updated_by_last_action? ||
                                  analytics_rb_template.updated_by_last_action?)

        ruby_block 'notify_push_config' do
          block do
            # Singular Notifier
            # Can do Sanity Check/Validation etc. here too
            new_platform_spec.save(action_handler)
          end
          action :nothing unless run_notify_push_config
          notifies :_push_config, "chef_platform_provision[prod]", :immediately
        end

      end

      # will only be accessible when notified by generate_config
      action :_push_config do
        ruby_block 'do_push_boostrap_files' do
          block do

            new_platform_spec.all_nodes.each do |server|
              machine_file "/var/chef/cache/platform/chef-server.rb.erb" do
                local_path local_chef_server_rb_path
                machine server['fqdn']
                action :upload
              end

              if with_analytics?
                machine_file '/var/chef/cache/platform/analytics.rb.erb' do
                  local_path local_analytics_rb_path
                  machine server['fqdn']
                  action :upload
                end
              end
            end

          end
          # action :nothing #if standalone_server_only || !rbm.updated_by_last_action?
          notifies :_run_bootstrap, "chef_platform_provision[prod]", :immediately
        end
        # machine_batch 'do_push_config' do
        #   action :converge
        #   new_platform_spec.all_nodes.each do |server|
        #     machine server['fqdn'] do
        #       driver new_platform_spec.driver_name
        #       machine_options machine_opts_for(server)
        #       files(
        #         '/var/chef/cache/platform/chef-server.rb.erb' => local_chef_server_rb_path,
        #         '/var/chef/cache/platform/analytics.rb.erb' => local_analytics_rb_path
        #       )
        #     end
        #   end
        #   notifies :_run_bootstrap, "chef_platform_provision[prod]", :immediately
        # end
      end

      action :_run_bootstrap do
        rbm = machine new_platform_spec.chef_server_bootstrap_backend['fqdn'] do
          driver new_platform_spec.driver_name
          attribute 'platform_node', new_platform_spec.chef_server_bootstrap_backend
          recipe "platform-node::server"
          action :nothing
          machine_options machine_opts_for(new_platform_spec.chef_server_bootstrap_backend)
          # converge true
        end

        rbm.run_action(:converge)

        ruby_block 'notify_reconfigure_all_non_bootstrap' do
          block do

            chef_server_files.each do |server_file|
              machine_file "/etc/opscode/#{server_file}" do
                local_path "#{local_chef_server_cache_path}/#{server_file}"
                machine new_platform_spec.chef_server_bootstrap_backend['fqdn']
                action :download
              end
            end

            if with_analytics?
              analytics_files.each do |analytics_file|
                machine_file "/etc/opscode-analytics/#{analytics_file}" do
                  local_path "#{local_analytics_cache_path}/#{analytics_file}"
                  machine new_platform_spec.chef_server_bootstrap_backend['fqdn']
                  action :download
                end
              end
            end

          end
          # action :nothing #if standalone_server_only || !rbm.updated_by_last_action?
          action :nothing unless rbm.updated_by_last_action?
          notifies :_push_boostrap_files, "chef_platform_provision[prod]", :immediately
        end

      end

      action :_push_boostrap_files do
        ruby_block 'do_push_boostrap_files' do
          block do

            new_platform_spec.all_nodes.each do |server|
              chef_server_files.each do |server_file|
                machine_file "/etc/opscode/#{server_file}" do
                  local_path "#{local_chef_server_cache_path}/#{server_file}"
                  machine server['fqdn']
                  action :upload
                end
              end

              if with_analytics?
                analytics_files.each do |analytics_file|
                  machine_file "/etc/opscode-analytics/#{analytics_file}" do
                    local_path "#{local_analytics_cache_path}/#{analytics_file}"
                    machine server['fqdn']
                    action :upload
                  end
                end
              end
            end

          end
          # action :nothing #if standalone_server_only || !rbm.updated_by_last_action?
          # notifies :_reconfigure_all_non_bootstrap, "chef_platform_provision[prod]", :immediately
        end
      end



      # will only be accessible when notified by _run_bootstrap
      action :_reconfigure_all_non_bootstrap do
        machine_batch 'reconfigure_all_non_bootstrap' do
          action :converge
          new_platform_spec.all_nodes.each do |server|
            next if current_platform_spec.is_bootstrap_backend?(server)
            machine server['fqdn'] do
              attribute 'platform_node', server
              recipe "platform-node::server" if run_server_recipe?(server)
              recipe "platform-node::analytics" if run_analytics_recipe?(server)
              driver current_platform_spec.driver_name
              machine_options machine_opts_for(server)
              converge true
            end
          end
        end
      end

      ##
      # Begin Non Action Methods

      attr_reader :policy_group, :new_platform_spec, :current_platform_spec, :rollback_platform_spec

      def load_current_resource
        @policy_group = new_resource.policy_group
        @current_platform_spec = Chef::Provisioner::ChefPlatformSpec.current_spec(policy_group)
        @new_platform_spec = Chef::Provisioner::ChefPlatformSpec.new_spec(policy_group,
                                                                          new_platform_data)
        new_platform_spec.nodes = all_ready_nodes if all_nodes_ready?
        new_platform_spec.all_nodes.each do |server|
          puts "NODE CLASS #{server.class}"
        end
        # puts new_platform_spec.get
      end

      ##
      # New Platform Data
      def new_platform_data
        platform_data = {}
        platform_data['driver'] = {}
        platform_data['chef_server'] = {}
        platform_data['analytics'] = {}
        platform_data['nodes'] = []
        platform_data['driver']['name'] = new_resource.driver_name
        platform_data['chef_server']['version'] = new_resource.chef_server_version
        platform_data['chef_server']['topology'] = new_resource.chef_server_topology
        platform_data['chef_server']['api_fqdn'] = new_resource.chef_server_api_fqdn
        platform_data['chef_server']['configuration'] = new_resource.chef_server_configuration
        platform_data['analytics']['version'] = new_resource.analytics_version
        platform_data['analytics']['api_fqdn'] = new_resource.analytics_api_fqdn
        platform_data['analytics']['configuration'] = new_resource.analytics_configuration
        platform_data['nodes'] = new_resource.nodes
        platform_data
      end

      ##
      # Machine Options

      def machine_opts_for(server)
        case new_platform_spec.driver_name
        when "ssh"
          ssh_machine_opts_for(server)
        when "vagrant"
          vagrant_machine_opts_for(server)
        when "docker"
          raise "Docker Driver Not Yet Implemented"
        when "aws"
          raise "Aws Driver Not Yet Implemented"
        when "lxc"
          raise "LXC Driver Not Yet Implemented"
        end
      end

      def vagrant_machine_opts_for(server)
        machine_opts = Chef::Provisioner::MachineOptions::Vagrant.generate_config(server)
        machine_opts
      end

      def ssh_machine_opts_for(server)
        machine_opts = Chef::Provisioner::MachineOptions::Ssh.generate_config(server)
        machine_opts
      end

      def run_analytics_recipe?(server)
        val = (server['service'] == "analytics") || false
        val
      end

      def run_chef_server_recipe?(server)
        val = (server['service'] == "chef-server") || false
        val
      end

      ##
      # Paths

      def platform_policy_group_cache_path
        ::File.join(Chef::Config[:chef_repo_path], "policies", policy_group, "cache")
      end

      def local_analytics_cache_path
        ::File.join(platform_policy_group_cache_path, "opscode-analytics")
      end

      def local_chef_server_cache_path
        ::File.join(platform_policy_group_cache_path, "opscode")
      end

      def local_analytics_rb_path
        ::File.join(local_analytics_cache_path, "analytics.rb")
      end

      def local_chef_server_rb_path
        ::File.join(local_chef_server_cache_path, "chef-server.rb")
      end

      def local_hostsfile_path
        ::File.join(platform_policy_group_cache_path, "hostsfile")
      end

      def chef_server_files
        %w(pivotal.pem webui_pub.pem private-chef-secrets.json webui_priv.pem)
      end

      def analytics_files
        %w(actions-source.json webui_priv.pem)
      end

      ##
      # Template Resources

      def hostsfile_template
        @hostsfile_template ||= begin
          ht = Chef::Resource::Template.new(local_hostsfile_path, run_context)
          ht.source("hostsfile.erb")
          ht.mode("0644")
          ht.cookbook("chef-platform-provision")
          ht.variables(
            :nodes => new_platform_spec.nodes
          )
          ht
        end
      end

      def analytics_rb_template
        @analytics_rb_template ||= begin
          arbt = Chef::Resource::Template.new(local_analytics_rb_path, run_context)
          arbt.source("analytics.rb.erb")
          arbt.mode("0644")
          arbt.cookbook("chef-platform-provision")
          arbt.variables(
            :chef_analytics => new_platform_spec.analytics_data
          )
          arbt
        end
      end

      def chef_server_rb_template
        @chef_server_rb_template ||= begin
          csrt = Chef::Resource::Template.new(local_chef_server_rb_path, run_context)
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
      end

      ####
      #
      # Top level Checks

      # Check if should run
      def should_run?
        val = (!all_nodes_ready? ||
               config_updated?)
      end

      # Check all configs
      def config_updated?
        val = (chef_server_config_updated? ||
               analytics_config_updated?)
      end

      # Check if all nodes are ready
      def all_nodes_ready?
        if current_platform_spec.nodes.nil?
          false
        else
          true
        end
      end

      def with_analytics?
        true
      end

      ##
      # Returns all ready nodes

      def all_ready_nodes
        current_platform_spec.nodes
      end

      ####
      #
      # Check Config Equalities

      def chef_server_config_updated?
        if !::File.exists?(local_chef_server_rb_path)
          true
        else
          current_hash = current_platform_spec.chef_server_data
          new_hash = new_platform_spec.chef_server_data
          val = current_hash.eql?(new_hash)
          puts "val #{val.to_s}"
          ret_val = val ? false : true
          ret_val
        end
      end

      def analytics_config_updated?
        if !::File.exists?(local_analytics_rb_path)
          true
        else
          current_hash = current_platform_spec.analytics_data
          new_hash = new_platform_spec.analytics_data
          val = current_hash.eql?(new_hash)
          puts "val #{val.to_s}"
          ret_val = val ? false : true
          ret_val
        end
      end

      def supermarket_config_updated?
        current_hash = current_platform_spec.supermarket_data
        new_hash = new_platform_spec.supermarket_data
        val = current_hash.eql?(new_hash)
        ret_val = val ? false : true
        ret_val
      end

      def delivery_config_updated?
        current_hash = current_platform_spec.delivery_data
        new_hash = new_platform_spec.delivery_data
        val = current_hash.eql?(new_hash)
        ret_val = val ? false : true
        ret_val
      end

    end
  end
end
