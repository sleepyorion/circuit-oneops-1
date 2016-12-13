name "gcp"
description "Google Cloud Platform"
auth "gcpsecretkey"

service "gcp-dns",
  :cookbook => 'gcp-dns',
  :source => [Chef::Config[:register], Chef::Config[:version].split(".").first].join('.'),
  :provides => { :service => 'dns' }