class Chef
  module Provisioner
    module Paths
      def platform_policy_group_cache_path
        ::File.join(Chef::Config[:chef_repo_path], "policies", policy_group, "cache")
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

    end
  end
end
