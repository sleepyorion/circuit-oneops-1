include_pack "base"

name "jenkins"
description "Jenkins"
type "Platform"
category "Web Application"

environment "single", {}

resource "secgroup",
         :cookbook => "oneops.1.secgroup",
         :design => true,
         :attributes => {
             "inbound" => '[ "22 22 tcp 0.0.0.0/0" ]'
         },
         :requires => {
             :constraint => "1..1",
             :services => "compute"
         }

resource 'java',
         :cookbook => 'oneops.1.java',
         :design => true,
         :requires => {
             :constraint => '1..1',
             :services => '*mirror',
             :help => 'Java Programming Language Environment'
         },
         :attributes => {}

resource 'os',
          :cookbook => 'oneops.1.os',
          :design => true,
          :attributes => {
            :ostype => 'centos-7.2'
          },
          :requires => {
            :constraint => "1..1",
            :services => "compute"
          }

resource "tomcat",
  :cookbook => "oneops.1.tomcat",
  :design => true,
  :requires => {
      :constraint => "1..1",
      :services=> "mirror"},
   :attributes => {
       'install_type' => 'binary'
   },
  :monitors => {     
      'HttpValue' => {:description => 'HttpValue',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_http_value!#{cmd_options[:url]}!#{cmd_options[:format]}',
                 :cmd_line => '/opt/nagios/libexec/check_http_value.rb $ARG1$ $ARG2$',
                 :cmd_options => {
                     'url' => '',
                     'format' => ''
                 },
                 :metrics => {
                     'value' => metric( :unit => '',  :description => 'value', :dstype => 'DERIVE'),
                     
                 }
       },  
        'Log' => {:description => 'Log',
                 :source => '',
                 :chart => {'min' => 0, 'unit' => ''},
                 :cmd => 'check_logfiles!logtomcat!#{cmd_options[:logfile]}!#{cmd_options[:warningpattern]}!#{cmd_options[:criticalpattern]}',
                 :cmd_line => '/opt/nagios/libexec/check_logfiles   --noprotocol --tag=$ARG1$ --logfile=$ARG2$ --warningpattern="$ARG3$" --criticalpattern="$ARG4$"',
                 :cmd_options => {
                     'logfile' => '/log/apache-tomcat/catalina.out',
                     'warningpattern' => 'WARNING',
                     'criticalpattern' => 'CRITICAL'
                 },
                 :metrics => {
                     'logtomcat_lines' => metric(:unit => 'lines', :description => 'Scanned Lines', :dstype => 'GAUGE'),
                     'logtomcat_warnings' => metric(:unit => 'warnings', :description => 'Warnings', :dstype => 'GAUGE'),
                     'logtomcat_criticals' => metric(:unit => 'criticals', :description => 'Criticals', :dstype => 'GAUGE'),
                     'logtomcat_unknowns' => metric(:unit => 'unknowns', :description => 'Unknowns', :dstype => 'GAUGE')
                 },
                 :thresholds => {
                   'CriticalLogException' => threshold('15m', 'avg', 'logtomcat_criticals', trigger('>=', 1, 15, 1), reset('<', 1, 15, 1)),
                 }
       },    
      'JvmInfo' =>  { :description => 'JvmInfo',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_tomcat_jvm',
                  :cmd_line => '/opt/nagios/libexec/check_tomcat.rb JvmInfo',
                  :metrics =>  {
                    'max'   => metric( :unit => 'B', :description => 'Max Allowed', :dstype => 'GAUGE'),
                    'free'   => metric( :unit => 'B', :description => 'Free', :dstype => 'GAUGE'),
                    'total'   => metric( :unit => 'B', :description => 'Allocated', :dstype => 'GAUGE'),
                    'percentUsed'  => metric( :unit => 'Percent', :description => 'Percent Memory Used', :dstype => 'GAUGE'),
                  },
                  :thresholds => {
                     'HighMemUse' => threshold('5m','avg','percentUsed',trigger('>',98,15,1),reset('<',98,5,1)),
                  }
                },
      'ThreadInfo' =>  { :description => 'ThreadInfo',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_tomcat_thread',
                  :cmd_line => '/opt/nagios/libexec/check_tomcat.rb ThreadInfo',
                  :metrics =>  {
                    'currentThreadsBusy'   => metric( :unit => '', :description => 'Busy Threads', :dstype => 'GAUGE'),
                    'maxThreads'   => metric( :unit => '', :description => 'Maximum Threads', :dstype => 'GAUGE'),
                    'currentThreadCount'   => metric( :unit => '', :description => 'Ready Threads', :dstype => 'GAUGE'),
                    'percentBusy'    => metric( :unit => 'Percent', :description => 'Percent Busy Threads', :dstype => 'GAUGE'),
                  },
                  :thresholds => {
                     'HighThreadUse' => threshold('5m','avg','percentBusy',trigger('>',90,5,1),reset('<',90,5,1)),
                  }
                },
      'RequestInfo' =>  { :description => 'RequestInfo',
                  :source => '',
                  :chart => {'min'=>0, 'unit'=>''},
                  :cmd => 'check_tomcat_request',
                  :cmd_line => '/opt/nagios/libexec/check_tomcat.rb RequestInfo',
                  :metrics =>  {
                    'bytesSent'   => metric( :unit => 'B/sec', :description => 'Traffic Out /sec', :dstype => 'DERIVE'),
                    'bytesReceived'   => metric( :unit => 'B/sec', :description => 'Traffic In /sec', :dstype => 'DERIVE'),
                    'requestCount'   => metric( :unit => 'reqs /sec', :description => 'Requests /sec', :dstype => 'DERIVE'),
                    'errorCount'   => metric( :unit => 'errors /sec', :description => 'Errors /sec', :dstype => 'DERIVE'),
                    'maxTime'   => metric( :unit => 'ms', :description => 'Max Time', :dstype => 'GAUGE'),
                    'processingTime'   => metric( :unit => 'ms', :description => 'Processing Time /sec', :dstype => 'DERIVE')                                                          
                  },
                  :thresholds => {
                  }
                }
}

resource "tomcat-daemon",
         :cookbook => "oneops.1.daemon",
         :design => true,
         :requires => {
             :constraint => "0..1",
             :help => "Restarts Tomcat"
         },
         :attributes => {
             :service_name => 'tomcat7',
             :use_script_status => 'true',
             :pattern => ''
         },
         :monitors => {
             'tomcatprocess' => {:description => 'TomcatProcess',
                           :source => '',
                           :chart => {'min' => '0', 'max' => '100', 'unit' => 'Percent'},
                           :cmd => 'check_process!:::node.workorder.rfcCi.ciAttributes.service_name:::!:::node.workorder.rfcCi.ciAttributes.use_script_status:::!:::node.workorder.rfcCi.ciAttributes.pattern:::!:::node.workorder.rfcCi.ciAttributes.secondary_down:::',
                           :cmd_line => '/opt/nagios/libexec/check_process.sh "$ARG1$" "$ARG2$" "$ARG3$" "$ARG4$"',
                           :metrics => {
                               'up' => metric(:unit => '%', :description => 'Percent Up'),
                           },
                           :thresholds => {
                               'TomcatDaemonProcessDown' => threshold('1m', 'avg', 'up', trigger('<=', 98, 1, 1), reset('>', 95, 1, 1))
                           }
             }
          }

# depends_on
 [{ :from => 'tomcat',:to => 'java' },
 { :from => 'tomcat-daemon',:to => 'tomcat' },
 { :from => 'download',:to => 'tomcat'},
 { :from => 'java',:to => 'os' } ].each do |link|
  relation "#{link[:from]}::depends_on::#{link[:to]}",
    :relation_name => 'DependsOn',
    :from_resource => link[:from],
    :to_resource   => link[:to],
    :attributes    => { "flex" => false, "min" => 1, "max" => 1 }
end

relation "fqdn::depends_on::compute",
  :only => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'from', "flex" => false, "min" => 1, "max" => 1 }

relation "fqdn::depends_on_flex::compute",
  :except => [ '_default', 'single' ],
  :relation_name => 'DependsOn',
  :from_resource => 'fqdn',
  :to_resource   => 'compute',
  :attributes    => { "propagate_to" => 'from', "flex" => true, "min" => 2, "max" => 10 }
                     
# managed_via
# ['java'].each do |from|
#   relation "#{from}::managed_via::compute",
#     :except => [ '_default' ],
#     :relation_name => 'ManagedVia',
#     :from_resource => from,
#     :to_resource   => 'compute',
#     :attributes    => { } 
# end
