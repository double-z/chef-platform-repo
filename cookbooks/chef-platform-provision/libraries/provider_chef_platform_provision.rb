require 'cheffish'
require 'chef/provisioning'
require 'chef/provider/lwrp_base'
require 'chef/provider/chef_node'
# require_relative 'helpers_paths'

class Chef
  class Provider
    class ChefPlatformProvision < Chef::Provider::LWRPBase

      def action_handler
        @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
      end

      ############################################
      #
      # Public Actions. Accessible from recipe.
      #
      #    - reconfigure
      #    - destroy_all
      #
      ############################################

      action :reconfigure do
        reconfigure_updated = should_run? ? action_do_reconfigure : false
        @new_resource.updated_by_last_action(reconfigure_updated)
      end

      action :destroy_all do
        action_allocate
        destroy_machines.run_action(:destroy)
        chef_server_rb_template.run_action(:delete) if destroy_machines.updated_by_last_action?
        analytics_rb_template.run_action(:delete) if destroy_machines.updated_by_last_action?
        current_platform_spec.delete(action_handler) if destroy_machines.updated_by_last_action?
        @new_resource.updated_by_last_action(destroy_machines.updated_by_last_action?)
      end

      ############################################
      #
      # Private Actions. Access is restricted
      #
      #    - allocate
      #    - ready
      #    - reconfigure_bootstrap
      #    - do_reconfigure
      #
      ############################################

      # PRIVATE ACTION: allocate
      action :allocate do
        [platform_policy_group_cache_path,
         local_chef_server_cache_path,
         local_analytics_cache_path
        ].each do |path|
          create_or_delete_directory(path)
        end
      end

      # PRIVATE ACTION: ready
      action :ready do
        if all_nodes_ready?
          @new_resource.updated_by_last_action(false)
        else
          action_allocate
          ready_machines.run_action(:converge)
          node_data = update_ready_machines(ready_machines.machines)
          new_platform_spec.nodes = node_data
          current_platform_spec.nodes = node_data
          current_platform_spec.save(action_handler)
        end
      end

      # PRIVATE ACTION: reconfigure_bootstrap
      action :reconfigure_bootstrap do
        action_ready unless all_nodes_ready?
        chef_server_rb_template.run_action(:create)
        analytics_rb_template.run_action(:create) if with_analytics?
        upload_platform_conf
        bootstrap_machine.run_action(:converge)
        if (bootstrap_machine.updated_by_last_action? && !chef_server_standalone_only?)
          download_chef_server_files
          upload_chef_server_files
          if with_analytics?
            download_analytics_files
            upload_analytics_files
          end
        end
        new_platform_spec.save(action_handler) if chef_server_standalone_only?
        bootstrap_machine.updated_by_last_action?
      end

      # PRIVATE ACTION: do_reconfigure
      action :do_reconfigure do
        bootstrap_updated = action_reconfigure_bootstrap
        unless chef_server_standalone_only?
          non_bootstrap_machines.run_action(:converge) if bootstrap_updated
          new_platform_spec.save(action_handler)
        end
        bootstrap_updated
      end

      ############################################
      #
      # Begin Non Action Methods
      #
      ############################################

      attr_reader :policy_group, :new_platform_spec, :current_platform_spec, :rollback_platform_spec

      def load_current_resource
        @policy_group = new_resource.policy_group
        @current_platform_spec = Chef::Provisioner::ChefPlatformSpec.current_spec(policy_group)
        @new_platform_spec = Chef::Provisioner::ChefPlatformSpec.new_spec(policy_group,
                                                                          new_platform_data)
        new_platform_spec.nodes = all_ready_nodes if all_nodes_ready?
      end

      ##
      # New Platform Data
      def new_platform_data
        data = {}
        data['driver'] = {}
        data['chef_server'] = {}
        data['analytics'] = {}
        data['nodes'] = []
        data['driver']['name'] = new_resource.driver_name
        data['chef_server']['version'] = new_resource.chef_server_version
        data['chef_server']['topology'] = new_resource.chef_server_topology
        data['chef_server']['api_fqdn'] = new_resource.chef_server_api_fqdn
        data['chef_server']['configuration'] = new_resource.chef_server_configuration
        data['analytics']['version'] = new_resource.analytics_version
        data['analytics']['api_fqdn'] = new_resource.analytics_api_fqdn
        data['analytics']['configuration'] = new_resource.analytics_configuration
        data['nodes'] = new_resource.nodes
        data
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
        m = Chef::Provisioner::MachineOptions::Vagrant.generate_config(server)
        m
      end

      def ssh_machine_opts_for(server)
        m = Chef::Provisioner::MachineOptions::Ssh.generate_config(server)
        m
      end

      ##
      # Paths

      def platform_policy_group_cache_path
        ::File.join(Chef::Config[:chef_repo_path],
                    "policies", policy_group, "cache")
      end

      def remote_cache_path
        '/var/chef/cache/platform/'
      end

      def local_chef_server_cache_path
        ::File.join(platform_policy_group_cache_path, "opscode")
      end

      def local_chef_server_rb_path
        ::File.join(local_chef_server_cache_path, "chef-server.rb")
      end

      def remote_chef_server_cache_path
        ::File.join(remote_cache_path, "opscode")
      end

      def remote_chef_server_conf_path
        "/etc/opscode"
      end

      def chef_server_files
        %W(pivotal.pem webui_pub.pem private-chef-secrets.json webui_priv.pem)
      end

      def local_analytics_cache_path
        ::File.join(platform_policy_group_cache_path, "opscode-analytics")
      end

      def local_analytics_rb_path
        ::File.join(local_analytics_cache_path, "analytics.rb")
      end

      def remote_analytics_cache_path
        ::File.join(remote_cache_path, "opscode-analytics")
      end

      def remote_analytics_conf_path
        "/etc/opscode-analytics"
      end

      def analytics_files
        %w(actions-source.json webui_priv.pem)
      end

      ##
      # Directory and Template Resources

      def create_or_delete_directory(path)
        d = ::Chef::Resource::Directory.new(path, run_context)
        d.recursive(true)
        if new_resource.action == :destroy_all
          d.run_action(:delete)
        else
          d.run_action(:create) unless ::File.exists?(path)
        end
      end

      def analytics_rb_template
        @analytics_rb_template ||= begin
          arbt = ::Chef::Resource::Template.new(local_analytics_rb_path,
                                                run_context)
          arbt.source("analytics.rb.erb")
          arbt.mode("0644")
          arbt.cookbook("chef-platform-provision")
          arbt.variables(
            :chef_analytics => new_platform_spec.analytics_data,
            :analytics_fqdn => new_resource.analytics_api_fqdn
          )
          arbt
        end
      end

      def chef_server_rb_template
        @chef_server_rb_template ||= begin
          csrt = ::Chef::Resource::Template.new(local_chef_server_rb_path,
                                                run_context)
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

      ##
      # Machine Resources

      def destroy_machines
        @destroy_machines ||= begin
          mbd = machine_batch 'machine_batch_destroy_all' do
            action :nothing
            new_platform_spec.all_nodes.each do |server|
              machine server['fqdn'] do
                driver new_platform_spec.driver_name
                machine_options machine_opts_for(server)
              end
            end
          end
          mbd
        end
      end

      def ready_machines
        @ready_machines ||= begin
          rmb = machine_batch 'machine_batch_ready_all' do
            new_platform_spec.all_nodes.each do |server|
              machine server['fqdn'] do
                driver new_platform_spec.driver_name
                machine_options machine_opts_for(server)
                recipe "platform-node"
              end
            end
            action :nothing
          end
          rmb
        end
      end

      def bootstrap_machine
        @bootstrap_machine ||= begin
          rbm = machine new_platform_spec.chef_server_bootstrap_backend['fqdn'] do
            driver new_platform_spec.driver_name
            machine_options machine_opts_for(new_platform_spec.chef_server_bootstrap_backend)
            attribute 'chef_platform', new_platform_spec.get_data
            attribute 'platform_node', new_platform_spec.chef_server_bootstrap_backend
            action :nothing
          end
          rbm
        end
      end

      def non_bootstrap_machines
        @non_bootstrap_machines ||= begin
          nbm = machine_batch 'reconfigure_non_bootstrap' do
            new_platform_spec.all_non_bootstrap_nodes.each do |server|
              machine server['fqdn'] do
                driver new_platform_spec.driver_name
                machine_options machine_opts_for(server)
                attribute 'chef_platform', new_platform_spec.get_data
                attribute 'platform_node', server
              end
            end
            action :nothing
          end
          nbm
        end
      end

      ##
      # File Download Resources

      def download_chef_server_files
        return if chef_server_standalone_only?
        chef_server_files.each do |server_file|
          chef_server_file_download = machine_file "/etc/opscode/#{server_file}" do
            local_path "#{local_chef_server_cache_path}/#{server_file}"
            machine new_platform_spec.chef_server_bootstrap_backend['fqdn']
            action :nothing
          end
          chef_server_file_download.run_action(:download) # unless chef_server_standalone_only?
        end
      end

      def download_analytics_files
        return if chef_server_standalone_only?
        analytics_files.each do |analytics_file|
          analytics_file_download =  machine_file "/etc/opscode-analytics/#{analytics_file}" do
            local_path "#{local_analytics_cache_path}/#{analytics_file}"
            machine new_platform_spec.chef_server_bootstrap_backend['fqdn']
            action :nothing
          end
          analytics_file_download.run_action(:download) # unless chef_server_standalone_only?
        end
      end

      ##
      # File Upload Resources

      def upload_platform_conf
        return if chef_server_standalone_only?
        new_platform_spec.all_nodes.each do |server|
          chef_server_conf_upload = machine_file "/var/chef/cache/platform/chef-server.rb.erb" do
            local_path local_chef_server_rb_path
            machine server['fqdn']
            action :nothing
          end
          chef_server_conf_upload.run_action(:upload) # unless chef_server_standalone_only?
          analytics_conf_upload =  machine_file "/var/chef/cache/platform/analytics.rb.erb" do
            local_path local_analytics_rb_path
            machine server['fqdn']
            action :nothing
          end
          analytics_conf_upload.run_action(:upload) # unless chef_server_standalone_only?
        end
      end

      def upload_chef_server_files
        return if chef_server_standalone_only?
        new_platform_spec.all_non_bootstrap_nodes.each do |server|
          chef_server_files.each do |server_file|
            chef_server_file_upload = machine_file "/etc/opscode/#{server_file}" do
              local_path "#{local_chef_server_cache_path}/#{server_file}"
              machine server['fqdn']
              only_if do
                ::File.exists?("#{local_chef_server_cache_path}/#{server_file}")
              end
              action :nothing
            end
            chef_server_file_upload.run_action(:upload) # if ::File.exists?("#{local_chef_server_cache_path}/#{server_file}")
          end
        end
      end

      def upload_analytics_files
        return if chef_server_standalone_only?
        new_platform_spec.all_non_bootstrap_nodes.each do |server|
          analytics_files.each do |analytics_file|
            analytics_file_upload =  machine_file "/etc/opscode-analytics/#{analytics_file}" do
              local_path "#{local_analytics_cache_path}/#{analytics_file}"
              machine server['fqdn']
              only_if do
                ::File.exists?("#{local_analytics_cache_path}/#{analytics_file}")
              end
              action :nothing
            end
            analytics_file_upload.run_action(:upload) # if ::File.exists?("#{local_analytics_cache_path}/#{analytics_file}")
          end
        end
      end

      def update_ready_machines(servers)
        node_data = []
        servers.each do |ready_machine|
          node_driver = Chef::Provider::ChefNode.new(ready_machine, run_context)
          node_driver.load_current_resource
          json = Chef::Provisioner::Helpers.deep_hashify(node_driver.new_json)
          new_platform_spec.all_nodes.each do |_server|
            server = Chef::Provisioner::Helpers.deep_hashify(_server)
            if (ready_machine.name.to_s == server['fqdn'])
              node_interfaces = json["automatic"]["network"]["interfaces"]
              node_interfaces["#{server['interface']}"]["addresses"].each do |k,v|
                server['ipaddress'] = k.to_s if (v["family"] == "inet")
                node_data << server if (server['ipaddress'] && (v["family"] == "inet"))
              end
            end
          end
        end
        node_data
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
        # if current_platform_spec.analytics_config.empty?
        #   false
        # else
        #   true
        # end
        true
      end

      def chef_server_standalone_only?
        if ((new_resource.chef_server_topology == "standalone") &&
            !with_analytics?)
          true
        else
          false
        end
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
          current_hash = current_platform_spec.chef_server_config
          new_hash = new_platform_spec.chef_server_config
          val = current_hash.eql?(new_hash)
          ret_val = val ? false : true
          ret_val
        end
      end

      def analytics_config_updated?
        if !::File.exists?(local_analytics_rb_path)
          true
        else
          current_hash = current_platform_spec.analytics_config
          new_hash = new_platform_spec.analytics_config
          val = current_hash.eql?(new_hash)
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
