#
# Cookbook Name:: platform-node
# Recipe:: server
#

directory '/etc/opscode' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  not_if 'test -d /etc/opscode'
end

# execute 'chef_server_reconfigure' do
#   command 'chef-server-ctl reconfigure'
#   action :nothing
# end

template '/etc/opscode/chef-server.rb' do
  local true
  source "/var/chef/cache/platform/chef-server.rb.erb"
  # notifies :run, 'execute[chef_server_reconfigure]', :immediately
  notifies :reconfigure, 'chef_ingredient[chef-server]'
end
