 for ii in 0 2 5;do ssh vagrant@33.33.33.2$ii sudo rm -rf /etc/opscode;done
 for ii in 0 2 5;do ssh vagrant@33.33.33.2$ii sudo rm -rf /etc/opscode-analyitcs;done
 for ii in 0 2 5;do ssh vagrant@33.33.33.2$ii sudo rm -rf /etc/chef;done
rm data_bags/prod/*
rm -rf nodes/*
rm -rf clients/*
rm -rf policies
