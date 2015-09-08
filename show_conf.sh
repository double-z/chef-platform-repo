 #!/bin/bash
 
 #for ii in 0 2 5;do echo $ii;echo;ssh vagrant@33.33.33.2$ii sudo cat /etc/hosts;echo;done
 for ii in 0 2 5;do echo $ii;echo;ssh vagrant@33.33.33.2$ii sudo hostname -f;echo;done
 for ii in 0 2 5;do echo $ii;echo;ssh vagrant@33.33.33.2$ii sudo hostname;echo;done
 #for ii in 0 2 5;do echo $ii;echo;ssh vagrant@33.33.33.2$ii sudo find /etc/opscode*;echo;done
 #for ii in 0 2 5;do echo $ii;echo;ssh vagrant@33.33.33.2$ii sudo cat /var/chef/cache/platform/opscode-analytics/analytics.rb.erb;echo;done

# for ii in 0 2 5;do echo $ii;echo;ssh vagrant@33.33.33.2$ii sudo cat /var/chef/cache/platform/chef-server.rb.erb;echo;done
# for ii in 0 2 5;do echo $ii;echo;ssh vagrant@33.33.33.2$ii sudo cat /var/chef/cache/platform/analytics.rb.erb;echo;done


# for ii in 0 2 5;do echo $ii;echo;ssh vagrant@33.33.33.2$ii ls /var/chef/cache/platform/;echo;done




