# # Load harness attributes from the config file
# harness_dir = Chef::Config[:chef_repo_path]
# config_json = JSON.parse(File.read(File.join(harness_dir, 'config-default.json')))

# default['harness'].tap do |harness|
#   # HARNESS_DIR is set by the Rakefile to the project root directory
#   # TODO reduntant standardize
#   harness['harness_dir'] = harness_dir
#   harness['repo_path'] = harness_dir
#   harness['vms_dir'] = File.join(harness_dir, 'vagrant_vms')

#   # host_cache_path is mapped to /tmp/cache on the VMs
#   # Used to push down packages
#   # TODO Move to machine_file and eliminate
#   harness['host_cache_path'] = File.join(harness_dir, 'cache')
#   harness['vm_mountpoint'] = '/tmp/ecm_cache'

#   # SSH key distribution for inter-machine trust
#   # TODO move file retrieval to machine_file and eliminate
#   harness['root_ssh'] = {
#     'privkey' => File.read(File.join(harness_dir, 'keys', 'id_rsa')),
#     'pubkey' => File.read(File.join(harness_dir, 'keys', 'id_rsa.pub'))
#   }


#   harness['root_ssh']['pubkey'] = File.read(File.join(harness_dir, 'keys', 'id_rsa.pub'))

#   # TODO Rename to driver
#   harness['provider'] = config_json['provider']
#   harness['vagrant'] = config_json['vagrant_options']
#   harness['ec2'] = config_json['ec2_options']
#   harness['vm_config'] = config_json['layout']
#   # TODO Eliminate default.
#   harness['default_package'] = config_json['default_package']
#   harness['run_pedant'] = config_json['run_pedant'] || true
#   # TODO factor out and only support current as of now on
#   harness['osc_install'] = config_json['osc_install'] || false
#   harness['osc_upgrade'] = config_json['osc_upgrade'] || false
#   harness['packages'] = config_json['packages']

#   # Provide an option to not monkeypatch the bugfixes
#   # TODO Deprecate
#   harness['apply_ec_bugfixes'] = config_json['apply_ec_bugfixes'] || false

#   # Provide an option to intentionally bomb out before running the upgrade reconfigure, so it can be done manually
#   harness['vm_config']['lemme_doit'] = config_json['lemme_doit'] || false

#   # Provide an option to run the "org torturer" which creates 900 orgs.  see: https://gist.github.com/irvingpop/bf4b983b5db7b5b9cbc7
#   harness['org_torture'] = config_json['org_torture'] || false

#   # addon packages
#   # TODO refactor so as to determine by distro/arch/version
#   harness['manage_package'] = config_json['manage_package']
#   harness['reporting_package'] = config_json['reporting_package']
#   harness['pushy_package'] = config_json['pushy_package']
#   harness['analytics_package'] = config_json['analytics_package']

#   # manage options
#   harness['manage_options'] = config_json['manage_options'] || {}

#   # loadtesters config
#   harness['loadtesters'] = config_json['loadtesters']
# end

