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

#
# compute delete using fog-google
#

require 'fog'
require 'fog/google'
require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
google_project = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:project]
project_service_id = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:project_service_id]
google_json = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:project_json_key]
region = node[:workorder][:services][:compute][cloud_name][:ciAttributes][:region]
rfcCi = node.workorder.rfcCi

connection = Fog::Compute::Google.new({
  :google_project => google_project,
  :google_client_email => project_service_id,
  :google_json_key_string => google_json,
})

server_name = node.server_name.downcase
server = connection.servers.get(server_name,region)

if server.nil?
  Chef::Log.info("Unable to find server, perhap it is already destroyed?")
else
  # retry for 2min for server to be deleted
  ok=false
  attempt=0
  max_attempts=6
  while !ok && attempt<max_attempts
    server = connection.servers.get(server_name,region)
    if (server.nil?) 
      ok = true
    else
      begin
        server.destroy     
      rescue Exception => e
        Chef::Log.info("delete failed: #{e.message}")
      end
      Chef::Log.info("state: "+server.state)
      attempt += 1
      sleep 20
    end 
  end

  if !ok
    Chef::Log.error("server still not in removed after 7 attempts over 2min. current state: "+server.state)
    exit 1
  end
end

puts server.inspect