 for ii in 0 2 5;do ssh vagrant@33.33.33.2$ii sudo rm -rf /etc/opscode;done
 for ii in 0 2 5;do ssh vagrant@33.33.33.2$ii sudo rm -rf /etc/opscode-analyitcs;done
 for ii in 0 2 5;do ssh vagrant@33.33.33.2$ii sudo rm -rf /etc/chef;done
rm data_bags/prod/chef_platform.json
rm -rf nodes/analytics1.json nodes/backend1.json nodes/frontend1.json nodes/js4.json
rm -rf clients/analytics1.json clients/backend1.json clients/frontend1.json
rm -rf policies
