#
# Cookbook Name:: platform-node
# Recipe:: analytics
#

directory '/etc/opscode-analytics' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  not_if 'test -d /etc/opscode-analytics'
end

execute 'analytics_reconfigure' do
  command 'opscode-analytics-ctl reconfigure'
  action :nothing
end

template '/etc/opscode-analytics/analytics.rb' do
  local true
  source "/var/chef/cache/platform/analytics.rb.erb"
  notifies :run, 'execute[analytics_reconfigure]', :immediately
end
