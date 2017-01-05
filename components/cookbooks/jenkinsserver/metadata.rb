name             'Jenkinsserver'
maintainer       'OneOps'
maintainer_email 'support@oneops.com'
license          'Apache License, Version 2.0'
license          'Apache 2.0'
description      'Installs/Configures Supervisord'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

grouping 'bom',
         :access => 'global',
         :packages => ['bom']

grouping 'default',
         :access => 'global',
         :packages => ['base', 'mgmt.catalog', 'mgmt.manifest', 'catalog', 'manifest', 'bom']

attribute 'jenkins_war',
					:description => 'Path to war file',
					:required => 'required',
					:default => 'https://updates.jenkins-ci.org/latest/jenkins.war',
					:format => {
						:help => 'Specify the path of where jenkins.war file can be retrieve from',
						:category => '1.Global',
						:order => 1
					}

attribute 'install_path',
		  :description => 'Installation Path',
		  :default     => 'admin',
		  :required    => 'required',
		  :format      => {
		  	:help      => 'Username of HTTP Server',
		  	:category  => '1.Global',
		  	:order     => 2
		  }

attribute 'http_port',
          :description => 'Default http port',
          :required    => 'required',
          :default     => 8080,
          :format      => {
            :help     => 'Port HTTP Server listens to',
            :category => '2.Server',
            :order    => 1
          }

attribute 'admin_username',
		  :description => 'Username',
		  :required    => 'required',
		  :default     => 'admin',
		  :format      => {
		  	:help      => 'Username of HTTP Server',
		  	:category  => '2.Server',
		  	:order     => 2
		  }

attribute 'admin_password',
		  :description => 'Password',
		  :encrypted   => true,
		  :default     => 'admin',
		  :required    => 'required',
		  :format      => {
		  	:help      => 'Username of HTTP Server',
		  	:category  => '2.Server',
		  	:order     => 3
		  }