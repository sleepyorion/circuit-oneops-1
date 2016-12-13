# Copyright 2016, Walmart Stores, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fog'
require 'fog/google'
require 'json'
#
# gcp compute add
#

puts "="*80
puts JSON.pretty_generate(node[:workorder])
puts "="*80

cloud_name = node[:workorder][:cloud][:ciName]
Chef::Log.info("Cloud = #{cloud_name}")

google_project = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:project]
project_service_id = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:project_service_id]
google_json = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:project_json_key]
region = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:region]

Chef::Log.info("Google Project = #{google_project} :: #{project_service_id}")

if node.ostype =~ /centos/ &&
  node.set["use_initial_user"] = true
  node.set["initial_user"] = "centos"
end

connection = Fog::Compute::Google.new({
  :google_project => google_project,
  :google_client_email => project_service_id,
  :google_json_key_string => google_json,
})

rfcCi = node["workorder"]["rfcCi"]
customer_domain = node["customer_domain"]

Chef::Log.info("compute::add -- name:"+node.server_name+" domain:"+customer_domain+" provider: "+cloud_name)  
Chef::Log.debug("rfcCi attrs:"+rfcCi["ciAttributes"].inspect.gsub("\n"," "))

disk_size = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:disksize]
size_map = JSON.parse(node[:workorder][:services][:compute][cloud_name][:ciAttributes][:sizemap])
compute_size_map = size_map[rfcCi[:ciAttributes][:size]]
image_map = JSON.parse(node[:workorder][:services][:compute][cloud_name][:ciAttributes][:imagemap])
private_key = node[:workorder][:payLoad][:SecuredBy].first[:ciAttributes][:private]
public_key = node[:workorder][:payLoad][:SecuredBy].first[:ciAttributes][:public].delete!("\n") + " #{node[:initial_user]}"
os_type = node[:workorder][:payLoad][:os][0][:ciAttributes][:ostype]
server_name = "#{node.server_name}".downcase!
disk_name = "#{server_name}-#{Time.now.to_i}"
source_image = ""

if image_map.key?(os_type)
  source_image = image_map[os_type]
else
  Chef::Log.info("Unable to find source image from cloud mapping")
  exit 1
end

disk = connection.disks.create(
    :name => disk_name,
    :size_gb => disk_size,
    :zone_name => region,
    :source_image => source_image)

disk.wait_for { disk.ready? }

server = connection.servers.create(
  :name => server_name,
  :disks => [disk],
  :machine_type => compute_size_map,
  :public_key => public_key,
  :zone_name => region,
  :username => node[:initial_user],
  #:tags => ["fog"],
)

# wait until server is ready before proceed
server.wait_for { server.ready? }

# This will mark the disk to be deleted when server is destroy
server.set_disk_auto_delete(true,server.disks[0]['deviceName']);

# retrieve server info again for up to date
server = connection.servers.get(server_name,region)

if !server.network_interfaces[0]['networkIP'].nil?
  puts "***RESULT:private_ip="+server.network_interfaces[0]['networkIP']
end
if !server.network_interfaces[0]['accessConfigs'][0]['natIP'].nil?
  puts "***RESULT:public_ip="+server.network_interfaces[0]['accessConfigs'][0]['natIP']
end

puts "***RESULT:instance_id=#{server.id}"
puts "***RESULT:server_image_name=#{source_image}"
node.set[:ip] = server.network_interfaces[0]['accessConfigs'][0]['natIP'] || server.network_interfaces[0]['networkIP']
include_recipe "compute::ssh_port_wait"
