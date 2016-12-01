name             "Gcp"
description      "Google Compute Cloud Service"
version          "0.1"
maintainer       "OneOps"
maintainer_email "support@oneops.com"
license          "Apache License, Version 2.0"

grouping 'default',
  :access => "global",
  :packages => [ 'base', 'mgmt.cloud.service', 'cloud.service' ],
  :namespace => true

attribute 'project',
  :description => "Google Project Name",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Specify Project Name',
    :category => '1.Project',
    :order => 1
  }

attribute 'project_service_id',
  :description => "Google Client Email",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Service Account Id',
    :category => '1.Project',
    :order => 2
  }

attribute 'region',
  :description => "Region",
  :default => "",
  :format => {
    :help => 'Region Name',
    :category => '2.Placement',
    :order => 1
  }

attribute 'availability_zones',
  :description => "Availability Zones",
  :data_type => "array",
  :default => '[]',
  :format => {
    :help => 'Availability Zones - Singles will round robin, Redundant will use platform id',
    :category => '2.Placement',
    :order => 2
  }  
  
attribute 'subnet',
  :description => "Subnet Name",
  :default => "",
  :format => {
    :help => 'Subnet Name is optional for placement of compute instances',
    :category => '2.Placement',
    :order => 3
  }

attribute 'sizemap',
  :description => "Sizes Map",
  :data_type => "hash",
  :default => '{
      "f1-micro":"f1.micro",
      "g1-small":"g1-small",
      "n1-standard-1":"n1-standard-1",
      "n1-standard-2":"n1-standard-2",
      "n1-standard-4":"n1-standard-4",
      "n1-standard-8":"n1-standard-8",
      "n1-standard-16":"n1-standard-16",
      "n1-standard-32":"n1-standard-32",
      "n1-highmem-2":"n1-highmem-2",
      "n1-highmem-4":"n1-highmem-4",
      "n1-highmem-8":"n1-highmem-8",
      "n1-highmem-16":"n1-highmem-16",
      "n1-highmem-32":"n1-highmem-32",
      "n1-highcpu-2":"n1-highcpu-2",
      "n1-highcpu-4":"n1-highcpu-4",
      "n1-highcpu-8":"n1-highcpu-8",
      "n1-highcpu-16":"n1-highcpu-16",
      "n1-highcpu-32":"n1-highcpu-32"
    }',
  :format => {
    :help => 'Map of generic compute sizes to provider specific',
    :category => '3.Mappings',
    :order => 1
  }

attribute 'imagemap',
  :description => "Images Map",
  :data_type => "hash",
  :default => '{"centos-6":"centos-6-v20161129",
                "centos-7":"centos-7-v20161129",
                "rhel-6":"rhel-6-v20161129",
                "rhel-7":"rhel-7-v20161129",
                "ubuntu-1204-precise","ubuntu-1204-precise-v20161109",
                "ubuntu-1404-trusty","ubuntu-1404-trusty-v20161109",
                "ubuntu-1604-xenial","ubuntu-1604-xenial-v20161115",
                "ubuntu-1610-yakkety","ubuntu-1610-yakkety-v20161020"}',
  :format => {
    :help => 'Map of generic OS image types to provider specific 64-bit OS image types',
    :category => '3.Mappings',
    :order => 2
  }

attribute 'disktype',
  :description => "Disk Type",
  :required => "required",
  :default => "persistent_disk",
  :format => {
    :help => 'Storage option - see provider documentation for details',
    :category => '4.Disk',
    :order => 1,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Persistent Disk','persistent_disk'],
      ['Local SSD','local_ssd'] ] }
  }

attribute 'disksize',
  :description => "Disk size",
  :default => '40',
  :format => {
    :help => 'Specify the disk size',
    :category => '4.Disk',
    :order => 2
  }

attribute 'repo_map',
  :description => "OS Package Repositories keyed by OS Name",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Map of repositories by OS Type containing add commands - ex) yum-config-manager --add-repo repository_url or deb http://us.archive.ubuntu.com/ubuntu/ hardy main restricted ',
    :category => '5.Operating System',
    :order => 2
  }

attribute 'env_vars',
  :description => "System Environment Variables",
  :data_type => "hash",
  :default => '{}',
  :format => {
    :help => 'Environment variables - ex) http => http://yourproxy, https => https://yourhttpsproxy, etc',
    :category => '5.Operating System',
    :order => 2
  }

# operating system
attribute 'ostype',
  :description => "OS Type",
  :required => "required",
  :default => "centos-7",
  :format => {
    :help => 'OS types are mapped to the correct cloud provider OS images - see provider documentation for details',
    :category => '5.Operating System',
    :order => 3,
    :form => { 'field' => 'select', 'options_for_select' => [
      ['Ubuntu 12.04 (precise)','ubuntu-1204-precise'],
      ['Ubuntu 14.04 (trusty)','ubuntu-1404-trusty'],
      ['Ubuntu 16.04 (xenial)','ubuntu-1604-xenial'],
      ['Ubuntu 16.10 (yakkety)','ubuntu-1610-yakkety'],
      ['CentOS 6','centos-6'],
      ['CentOS 7','centos-7'],
      ['RedHat 6','rhel-6'],
      ['RedHat 7','rhel-7'] ] }
  }
