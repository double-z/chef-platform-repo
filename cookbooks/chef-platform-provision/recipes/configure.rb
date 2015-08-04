#
# Cookbook Name:: chef-platform-provision
# Recipe:: configure
#
# Copyright (c) 2015 Zack Zondlo, All Rights Reserved.

## 
# This basically Setups up hostsfiles. Gets run on Initial Setup
# And is Notified When topology changes(?)

machine_batch 'configure' do

  machine topology.bootstrap_backend_or_standalone_machine_name do
    action :ready
    attribute %w[ chef-platform server bootstrap enable ], true
    attribute %w[ chef-platform server role ], topology.backend_or_standalone
    attribute %w[ provision phase ], 'setup'
  end

  machine topology.secondary_backend_machine_name do
    action :ready
    attribute %w[ chef-platform server bootstrap enable ], topology.is_bootstrap_node?
    attribute %w[ chef-platform server role ], 'backend'
    attribute %w[ provision phase ], 'setup'    
    only_if do
      topology.is_ha?
    end
  end

  topology.frontends.each do |fe|
    machine topology.frontend_machine_name(fe) do
      action :converge
      attribute %w[ provision phase ], 'setup'
    end
  end if !topology.is_standlone?

end