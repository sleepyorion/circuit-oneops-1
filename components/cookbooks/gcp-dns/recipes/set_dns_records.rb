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

# Cookbook Name:: fqdn
# Recipe:: set_dns_entries
#
# uses node[:entries] list of dns entries based on entrypoint, aliases, zone, and platform to update dns
# no ManagedVia - recipes will run on the gw

require 'fog/google'

extend Fqdn::Base
Chef::Resource::RubyBlock.send(:include, Fqdn::Base)

cloud_name = node[:workorder][:cloud][:ciName]
google_project = node[:workorder][:services][:dns][cloud_name][:ciAttributes][:project]
project_service_id = node[:workorder][:services][:dns][cloud_name][:ciAttributes][:project_service_id]
google_json = node[:workorder][:services][:dns][cloud_name][:ciAttributes][:project_json_key]
zone_name = node[:workorder][:services][:dns][cloud_name][:ciAttributes][:zone]
ns = node[:workorder][:services][:dns][cloud_name][:ciAttributes][:authoritative_server]

connection = Fog::DNS::Google.new({
  :google_project => google_project,
  :google_client_email => project_service_id,
  :google_json_key_string => google_json,
  })

zones = connection.zones.all
zone = nil

unless zones.size == 0
  zone = zones.find{|zone| zone.domain.eql?(zone_name+'.')}
  if zone.nil?
    Chef::Log.error("Could not get valid zone from nameserver")
    exit 1
  end
end

clean_set = []
deletable_values = []
if node.has_key?("deletable_entries")
  node.deletable_entries.each do |deletable_entry|
    if deletable_entry[:values].is_a?(String)
      deletable_values.push(deletable_entry[:values])
    else
      deletable_values += deletable_entry[:values]
    end
  end
end
deletable_values.uniq!
Chef::Log.debug("DELETABLE set: #{deletable_values.inspect}")

#
# delete / create dns entries
#
node[:entries].each do |entry|
  dns_match = false
  dns_name = entry[:name] + '.'
  dns_values = entry[:values].is_a?(String) ? Array.new([entry[:values]]) : entry[:values]
  dns_type = get_record_type(dns_name, dns_values).upcase
  existing_dns = get_existing_dns(dns_name,ns)

  Chef::Log.info("new values:"+dns_values.sort.to_s)
  Chef::Log.info("existing:"+existing_dns.sort.to_s)
  existing_comparison = existing_dns.sort <=> dns_values.sort

  dns_match = false
  if existing_comparison == 0
    dns_match = true
  end

  if (!dns_match || node[:dns_action] == "delete") && existing_dns.size > 0

    # cleanup or delete
    clean_set = existing_dns.clone
    existing_dns.each do |existing_entry|

      if deletable_values.include?(existing_entry) &&
         (dns_values.include?(existing_entry) && node[:dns_action] == "delete") ||
         # value was in previous entry, but not anymore
         (!dns_values.include?(existing_entry) &&
          node.previous_entries.has_key?(dns_name) &&
          node.previous_entries[dns_name].include?(existing_entry) &&
          node[:dns_action] != "delete")

        delete_type = get_record_type(dns_name, existing_dns).upcase
        Chef::Log.info("delete #{delete_type}: #{dns_name} to #{existing_dns.to_s}")

        record = zone.records.get(dns_name, delete_type)

        if record.nil?
          Chef::Log.error("could not get record: #{dns_name} #{delete_type}")
          exit 1
        end
        record.destroy
      end

    end
  end

  # delete workorder skips the create call
  if node[:dns_action] == "delete"
    next
  end

  ttl = 60
  if node.workorder.rfcCi.ciAttributes.has_key?("ttl")
    ttl = node.workorder.rfcCi.ciAttributes.ttl.to_i
  end

  Chef::Log.info("create #{dns_type}: #{dns_name} to #{dns_values.to_s}") if !dns_values.empty?

  if verify(dns_name,dns_values,ns,1)
    Chef::Log.info("exists - skipping create")
    next
  end

  record = zone.records.get(dns_name, dns_type)
  if record.nil?
    record = zone.records.create(
      :rrdatas => dns_values,
      :name  => dns_name,
      :type  => dns_type,
      :ttl => ttl
    )
  else
    new_vals = record.value.clone
    new_vals += dns_values
    new_vals.uniq!
    record.modify(value: new_vals)
  end

  if !verify(dns_name,dns_values,ns)
    fail_with_fault "could not verify: #{dns_name} to #{dns_values} on #{ns} after 5min."
  end

end
