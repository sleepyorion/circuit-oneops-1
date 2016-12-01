name "gcp-us-west1-a"
description "Google Cloud Platform - US West1-a Region (The Dalles,Oregon)"
auth "gcpsecretkey"

image_map = '{
      "centos-7.2":"centos-7-v20161027"
    }'

repo_map = '{
      "centos-7.2":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++"
}'

service "us-west1-a",
  :cookbook => 'gcp',
  :provides => { :service => 'compute' },
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :attributes => {
    :region => 'us-west1-a',
    :imagemap => image_map,
    :repo_map => repo_map
  }
