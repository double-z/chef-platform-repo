#
# Cookbook Name:: runit
# Provider:: service
#
# Copyright 2011, Joshua Timberman
# Copyright 2011, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/resource/lwrp_base'
require 'cheffish'
require 'chef/provisioning'
require 'cheffish/merged_config'
require 'pp'
class Chef
  class Resource
    class ChefPlatformProvision < Chef::Resource::LWRPBase

      self.resource_name = 'chef_platform_provision'

      def initialize(*args)
      	puts "INITIALIZE"
      	puts "INITIALIZE"
      	puts "INITIALIZE"
      	puts "INITIALIZE"
      	puts "INITIALIZE"
      	puts "INITIALIZE"
        args.each do |k|
          # raise "YUP" if !k.is_a?(ChefDK::ProvisioningData::Context)
          policy_group(k) if k.kind_of?(String)
        end
        args.collect! { |element|
          (element.kind_of?(String)) ? Chef::Config[:node_name] : element
        }
        name = "prod"
        super
        # pp run_context.instance_variables
        @chef_server = Cheffish.default_chef_server
        @chef_environment = run_context.cheffish.current_environment
        @driver = run_context.chef_provisioning.current_driver
        @machine_options = run_context.chef_provisioning.current_machine_options
        policy_hash = JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'Policyfile.lock.json')))
        # @chef_platform_harness_attrs = JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'chef-platform-spec.json')))
#        chef_platform_config = JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'chef-platform-spec.json')))
        # @platform_data = chef_platform_config['chef_platform']
 #       @harness_attributes = JSON.parse(::File.read(::File.join(Chef::Config[:chef_repo_path], 'attrsout.json')))
        @platform_attributes = policy_hash
        @policy_name = policy_hash["policy_name"] || {}
        @policy_revision_id = policy_hash["revision_id"] || {}
        @policy_default_attributes = policy_hash["default_attributes"] || {}
        @policy_default_attributes = policy_hash["default_attributes"] || {}
        @policy_override_attributes = policy_hash["override_attributes"] || {}
        policy_merged_attributes = Chef::Mixin::DeepMerge.merge(@policy_default_attributes, @policy_override_attributes)
        # @platform_data = policy_merged_attributes['chef_platform']
      end

      def policy_group(arg_val = nil)
      	@policy_group ||= arg_val
      end

      # This includes attributes from the Cheffish::Node resources - allows us
      # to specify things like `run_list`, `chef_server`, etc.
      Cheffish.node_attributes(self)

      actions :allocate, :ready, :test_ready, :setup, :converge, :reconfigure, :generate_config, :push_config, :destroy, :destroy_all, :stop, :bootstrap, :deploy
      default_action :nothing

      attribute :merged_platform_data, :kind_of => Hash
      attribute :policy_merged_attributes, :kind_of => Hash
      attribute :policy_override_attributes, :kind_of => Hash
      attribute :policy_default_attributes, :kind_of => Hash
      attribute :platform_attributes, :kind_of => Hash
      attribute :init_time, :kind_of => String, :default => Time.now.strftime("%Y%m%d%H%M%S")
      attribute :platform_data, :kind_of => Hash
      attribute :chef_platform_harness_attrs, :kind_of => Hash
      attribute :log_all, :kind_of => [ TrueClass, FalseClass ], :default => false
      attribute :policy_group, :kind_of => String

    end
  end
end


        # @name = run_context.node.name
        # puts "INITIALIZE"
        # p @policy_group
        # p @name
        # puts "INITIALIZE"
        # pp
        # puts args.class
        # args.each do |k|
          # pp k.inspect
          # instance_variables if !k.kind_of?(String)
        # end
        # puts "INITIALIZE"
        # pp self.inspect
        # pp
        # run_context.each do |k|
        # pp k.inspect
        # end
