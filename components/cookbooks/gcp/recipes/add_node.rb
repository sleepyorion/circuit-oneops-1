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
require 'ap'
#
# gcp compute add
#

def exit_with_error(msg)
  Chef::Log.error(msg)
  puts "***FAULT:FATAL=#{msg}"
  e = Exception.new(msg)
  e.set_backtrace(msg)
  raise e
end

ap node.workorder

cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
google_project = compute_service[:project]
project_service_id = compute_service[:project_service_id]
google_json = google_json = compute_service[:project_json_key]
region = compute_service[:region]

availability_zones = []
availability_zone = ""

if compute_service.has_key?("availability_zones") && !compute_service[:availability_zones].empty?
  availability_zones = JSON.parse(compute_service[:availability_zones])
end

if availability_zones.size > 0
  case node.workorder.box.ciAttributes.availability
  when "redundant"
    instance_index = node.workorder.rfcCi.ciName.split("-").last.to_i + node.workorder.box.ciId
    index = instance_index % availability_zones.size
    availability_zone = availability_zones[index]
  else
    random_index = rand(availability_zones.size)
    availability_zone = availability_zones[random_index]
  end
end

Chef::Log.info("Google Project = #{google_project} :: #{project_service_id} :: az #{availability_zone}")

# Override initial user with google
node.set["use_initial_user"] = true
initial_user = compute_service[:initial_user]
node.set[:initial_user] = "google"


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
secgroup = node[:workorder][:payLoad][:DependsOn][0][:ciName]

if server_name.length > 63 
  msg = "#{server_name} exceeded 64 characters"
  exit_with_error(msg)
end

source_image = ""

if image_map.key?(os_type)
  source_image = image_map[os_type]
else
  msg = "Unable to find source image from cloud mapping"
  exit_with_error(msg)
end

# Get connection
connection = Fog::Compute::Google.new({
  :google_project => google_project,
  :google_client_email => project_service_id,
  :google_json_key_string => google_json,
})

disk = connection.disks.create(
  :name => server_name,
  :size_gb => disk_size,
  :zone_name => availability_zone,
  :source_image => source_image)

disk.wait_for { disk.ready? }

  # Create the compute
server = connection.servers.create(
  :name => server_name,
  :disks => [disk],
  :machine_type => compute_size_map,
  :public_key => public_key,
  :zone_name => availability_zone,
  :username => node[:initial_user],
  :tags => [secgroup],
)

# wait until server is ready before proceed
server.wait_for { server.ready? }

# This will mark the disk to be deleted when server is destroy
server.set_disk_auto_delete(true,server.disks[0]['deviceName']);

# retrieve server info again for up to date
server = connection.servers.get(server_name,availability_zone)

if !server.network_interfaces[0]['networkIP'].nil?
  puts "***RESULT:private_ip="+server.network_interfaces[0]['networkIP'] 
end

if !server.network_interfaces[0]['accessConfigs'][0]['natIP'].nil?
  puts "***RESULT:public_ip="+server.network_interfaces[0]['accessConfigs'][0]['natIP']
end

puts "***RESULT:instance_id=#{server.id}"
puts "***RESULT:server_image_name=#{source_image}"
node.set[:ip] = server.network_interfaces[0]['accessConfigs'][0]['natIP'] || server.network_interfaces[0]['networkIP']
puts "***RESULT:dns_record=#{node[:ip]}"
puts "***RESULT:availability_zone=#{availability_zone}"
puts "***RESULT:server_image_name=" + source_image

include_recipe "compute::ssh_port_wait"