module Provisioner
  def self.deep_hashify(machine_options)
    if machine_options.respond_to?(:to_hash)
      hash = machine_options.to_hash

      hash.inject({}){|result, (key, value)|
        if value.respond_to?(:to_hash)
          new_value = deep_hashify(value)
        else
          new_value = value
        end
        result[key] = new_value
        result
      }
    end
  end

  def self.log_all_data(given_platform_spec)
    # omnibus = JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'Policyfile.lock.json'))) # new_resource.merged_platform_data.to_hash # JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'omnibus_private_chef.rb')))
    # omnibuspl = omnibus['default_attributes']['chef_platform']
    # file "#{Chef::Config[:chef_repo_path]}/policy_attributes.yml" do
    #   content omnibuspl.to_yaml
    #   action :create
    # end

    # apd("new_resource.platform_data", new_resource.platform_data)
    # apd("new_resource.policy_default_attributes", new_resource.policy_default_attributes)
    # apd("new_resource.policy_merged_attributes", new_resource.policy_merged_attributes)
    apd("all_data", given_platform_spec.get)
    apd("all_nodes", given_platform_spec.all_nodes)
    apd("chef_server_nodes", given_platform_spec.chef_server_nodes)
    apd("chef_server_frontend_nodes", given_platform_spec.chef_server_frontend_nodes)
    apd("chef_server_non_bootstrap_nodes", given_platform_spec.chef_server_non_bootstrap_nodes)
    apd("chef_server_bootstrap_backend", given_platform_spec.chef_server_bootstrap_backend)
    apd("chef_server_secondary_backend", given_platform_spec.chef_server_secondary_backend)
    apd("chef_server_config", given_platform_spec.chef_server_config)
    apd("analytics_nodes", given_platform_spec.analytics_nodes)
    apd("supermarket_nodes", given_platform_spec.supermarket_nodes)
    apd("delivery_nodes", given_platform_spec.delivery_nodes)
    apd("delivery_server_nodes", given_platform_spec.delivery_server_node)
    apd("delivery_build_nodes", given_platform_spec.delivery_build_nodes)

    log_test_if("is_chef_server?")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_chef_server?(server)
        puts "Chef Server #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Chef Server #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_bootstrap_backend?")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_bootstrap_backend?(server)
        puts "Bootstrap Backend #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Bootstrap Backend #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_secondary_backend?")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_secondary_backend?(server)
        puts "Secondary Backend #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Secondary Backend #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_backend")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_backend?(server)
        puts "Backend #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Backend #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_frontend")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_frontend?(server)
        puts "Frontend #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Frontend #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_analytics")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_analytics?(server)
        puts "Analytics #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Analytics #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_supermarket")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_supermarket?(server)
        puts "Supermarket #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Supermarket #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_delivery")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_delivery?(server)
        puts "Delivery #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Delivery #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_delivery_server")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_delivery_server?(server)
        puts "Delivery Server #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Delivery Server #{server['node_name']}"
      end
    end
    puts

    log_test_if("is_delivery_build?")
    given_platform_spec.all_nodes.each do |server|
      if given_platform_spec.is_delivery_build?(server)
        puts "Delivery Build #{server['node_name']}"
      else
        puts "#{server['node_name']} NOT Delivery Build #{server['node_name']}"
      end
    end
  end

  def self.apd(name, data)
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

  def self.apl(data)
    ap data, options = {
      :indent => -2,
      :index => false,
      :color => {
        :hash  => :pale,
        :class => :white
      }
    }
  end

  def self.log_test_if(name)
    puts "=========================================================="
    puts
    puts "TEST IF: #{name}"
    puts
  end
end
