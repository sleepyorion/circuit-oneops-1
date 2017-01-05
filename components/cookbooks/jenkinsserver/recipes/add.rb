
node.set['jenkins_server']['http_port'] = node.workorder.rfcCi.ciAttributes.http_port
node.set['jenkins_server']['admin_username'] = node.workorder.rfcCi.ciAttributes.admin_username
node.set['jenkins_server']['admin_password'] = node.workorder.rfcCi.ciAttributes.admin_password
node.set['jenkins_server']['install_path'] = node.workorder.rfcCi.ciAttributes.install_path
node.set['jenkins_server']['jenkins_war'] = node.workorder.rfcCi.ciAttributes.jenkins_war

if !node['etc']['passwd']['jenkins']
	user "jenkins" do
		manage_home false
	  shell "/bin/false"
	  system true
	end
end

include_recipe "jenkinsserver::update"


