name             "Gcp-dns"
description      "Google DNS Cloud Service"
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

attribute 'project_json_key',
  :description => "Google JSON Key",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Google JSON Key',
    :category => '1.Project',
    :order => 3
  }
  
attribute 'zone',
  :description => "Zone",
  :default => "",
  :format => {
    :help => 'Specify the zone name where to insert DNS records', 
    :category => '2.DNS',
    :order => 1
  }
   
attribute 'cloud_dns_id',
  :description => "Cloud DNS Id",
  :required => "required",
  :default => "",
  :format => {
    :help => 'Cloud DNS Id - prepended to zone name, but replaced w/ fqdn.global_dns_id for GLB',
    :category => '2.DNS',
    :order => 2
  }

attribute 'authoritative_server',
  :description => "authoritative_server",
  :default => "",
  :format => {
    :help => 'Explicit authoritative_server for verification - useful for testing. If not set uses NS records for the zone.',
    :category => '2.DNS',
    :order => 3
  }  
