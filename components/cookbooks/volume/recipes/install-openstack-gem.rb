
#manually install fog-openstack dependency until we can
#move to Ruby 2.1

["#{File.expand_path("../../files/fog-openstack-0.1.24.gem",__FILE__)}",
 'fog -v 1.38.0', 'fog-core -v 1.45.0',
 'fog-cloudatcost -v 0.1.2', 'fog-dynect -v 0.0.3', 'fog-google -v 0.1.0',
 'fog-rackspace -v 0.1.5', 'fog-vsphere -v 1.5.1', 'rbvmomi -v 1.11.6',
 'trollop -v 2.1.2', 'fog-xenserver -v 0.3.0'].each do |command|
  system("gem install #{command} --ignore-dependencies --no-ri --no-rdoc")
end