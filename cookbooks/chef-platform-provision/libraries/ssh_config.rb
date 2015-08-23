# encoding: utf-8

class SshConfigHelper

  def self.generate_config(server)
    local_provisioner_options = {
      :transport_options => {
        'ip_address' => server['machine_options_ipaddress'],
        'username' => 'vagrant',
        'ssh_options' => {
          'password' => 'vagrant'
        }
      }
    }
  end

end
