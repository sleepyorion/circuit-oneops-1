require 'digest/md5'
require 'json'

cloud_name = node[:workorder][:cloud][:ciName]
compute_service = node[:workorder][:services][:compute][cloud_name][:ciAttributes]
google_project = compute_service[:project]
project_service_id = compute_service[:project_service_id]
google_json = google_json = compute_service[:project_json_key]
secgroup = node[:workorder][:rfcCi][:ciName]
rules = JSON.parse(node[:workorder][:rfcCi][:ciAttributes][:inbound])
network = "https://www.googleapis.com/compute/v1/projects/#{google_project}/global/networks/default"

connection = Fog::Compute::Google.new({
        :google_project => google_project,
        :google_client_email => project_service_id,
        :google_json_key_string => google_json,
})

fw_rules = connection.firewalls.all()
filtered_rules = fw_rules.select { |rule| rule.description.eql?(secgroup) }
rules = JSON.parse(node[:workorder][:rfcCi][:ciAttributes][:inbound])

# add firewall rule port
rules.each do |r|
  rule_name = "#{secgroup}-#{Digest::MD5.hexdigest(Marshal::dump(r))}"
  Chef::Log.debug("rule_name :: #{rule_name}")
  res =  filtered_rules.select { |rule| rule.name.eql?(rule_name) }

  if res.size > 0
    break
  else
    self_link = "https://www.googleapis.com/compute/v1/projects/#{google_project}/global/firewalls/#{rule_name}"
    (min,max,protocol,cidr) = r.split(" ")
    allowed=[{"IPProtocol"=>"#{protocol}", "ports"=>["#{min}-#{max}"]}]
    source_range = [cidr]
    rule = connection.firewalls.new(:name => rule_name, :allowed => allowed, :network => 'default',
        :self_link => self_link, :kind => "compute#firewall",
        :source_ranges => source_range, :target_tags => [secgroup], :description => secgroup)
    Chef::Log.info("Rule is ======= #{rule_name}")
    Chef::Log.info("allowed =#{allowed}")
    Chef::Log.info("source_range = #{source_range}")
    rule.save
  end
end

# GCP doesn't really have secgroup
node.set[:secgroup][:group_id] = secgroup
node.set[:secgroup][:group_name] = secgroup