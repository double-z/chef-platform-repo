#
# Specification for a platform. Sufficient information to find and contact it
# after it has been set up.
#
# class Chef
#   module Provisioning
module Provisioner
  class PlatformSpec

    # x
    #     def initialize(type, platform_data)
    #       case type
    #       when :new_resource
    #         platform_data = 'new_resource'
    #       when :current_resource
    #         platform_data = 'current_resource'
    #       else
    #       end

    def initialize(platform_data)
      @platform_data = ::Provisioner.deep_hashify(platform_data)
    end

    attr_reader :platform_data

    ###
    #
    # Driver Name and Machine Options
    #

    def platform_data=(data)
      platform_data = data
    end

    def driver
      platform_data['driver']
    end

    def driver_name
      driver['name'] ||= ""
    end

    def driver_name=(value)
      driver['name'] = value
    end

    def driver_machine_options
      driver['machine_options'] ||= {}
    end

    def driver_machine_options=(value)
      driver['machine_options'] = value
    end

    ###
    #
    # role_machine_options - Role Specific Opts, I.E frontends are m3.medium, BE m3.large
    #

    def machine_options
      platform_data['machine_options']
    end

    ###
    #
    # chef_server data
    #
    def chef_server
      platform_data['chef_server'] ||= {}
    end

    def chef_server_configuration
      chef_server['configuration']
    end

    def chef_server_configuration=(value)
      chef_server['configuration'] = value if value
    end

    ###
    #
    # Nodes are an Array of Hashes With Machine Specific Config
    #

    def nodes
      platform_data['nodes']
    end

    # def node_test
    #   platform_data['node_test']
    # end

    def nodes=(nodes_array)
      platform_data['nodes'] ||= []
      platform_data['nodes'] = nodes_array
    end

    # def node_data(server_name)
    #   nodes[server_name]
    # end

    # def node_ip(server)
    # end

    ###
    #
    # analytics data
    #
    def analytics
      platform_data['analytics'] ||= {}
    end

    def analytics_configuration
      analytics['configuration']
    end

    def analytics_configuration=(value)
      analytics['configuration'] = value if value
    end

    ###
    #
    #  supermarket data
    #
    def supermarket
      platform_data['supermarket'] ||= {}
    end

    def supermarket_configuration
      supermarket['configuration']
    end

    def supermarket_configuration=(value)
      supermarket['configuration'] = value if value
    end

    ###
    #
    # delivery data
    #


    #
    # Save this platform_data to the server.  If you have significant information that
    # could be lost, you should do this as quickly as possible.  platform_data will be
    # saved automatically for you after allocate_platform and ready_platform.
    #

    def save(action_handler)
      raise "save unimplemented"
    end

    def status
      platform_data['status']
    end

    def status=(value)
      platform_data['status'] = value
    end

  end
end
