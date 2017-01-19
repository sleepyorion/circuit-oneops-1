name "gcp-asia-northeast-1"
description "Google Cloud Platform - Northeastern Asia-Pacific Region (Tokyo, Japan)"
auth "gcpsecretkey"

image_map = '{
  "centos-6":"centos-6-v20161129",
  "centos-7.2":"centos-7-v20161129",
  "rhel-6":"rhel-6-v20161129",
  "rhel-7":"rhel-7-v20161129",
  "ubuntu-1204-precise","ubuntu-1204-precise-v20161109",
  "ubuntu-1404-trusty","ubuntu-1404-trusty-v20161109",
  "ubuntu-1604-xenial","ubuntu-1604-xenial-v20161115",
  "ubuntu-1610-yakkety","ubuntu-1610-yakkety-v20161020"
}'

repo_map = '{
  "centos-6.3":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
  "centos-6.4":"yum -d0 -e0 -y install rsync; rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
  "centos-7.0":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++",
  "centos-7.2":"sudo yum clean all; sudo yum -d0 -e0 -y install rsync yum-utils; sudo yum -d0 -e0 -y install epel-release; sudo yum -d0 -e0 -y install gcc-c++"
}'

service "gcp-asia-east-1",
	:cookbook => 'gcp',
	:provides => { :service => 'compute'},
	:source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
	:attributes => {
		:region => 'asia-east-1',
		:availability_zones => "[\"asia-northeast1-a\",\"asia-northeast1-b\",\"asia-northeast1-c\"]",
		:imagemap => image_map,
		:repo_map => repo_map
	}