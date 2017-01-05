node.set['jenkins_server']['http_port'] = node.workorder.rfcCi.ciAttributes.http_port
node.set['jenkins_server']['admin_username'] = node.workorder.rfcCi.ciAttributes.admin_username
node.set['jenkins_server']['admin_password'] = node.workorder.rfcCi.ciAttributes.admin_password
node.set['jenkins_server']['install_path'] = node.workorder.rfcCi.ciAttributes.install_path
node.set['jenkins_server']['jenkins_war'] = node.workorder.rfcCi.ciAttributes.jenkins_war

directory "#{node['jenkins_server']['install_path']}" do
	owner 'jenkins'
	recursive true
end

remote_file "#{node['jenkins_server']['install_path']}/jenkins.war" do
	source "#{node['jenkins_server']['jenkins_war']}"
	owner 'jenkins'
end

template "/etc/supervisord.d/jenkins_server.conf" do
	source "jenkins_server.erb"
end

::Chef::Recipe.send(:include, JenkinsHelper)

reload_start_jenkins()

version = get_jenkins_version("#{node['jenkins_server']['install_path']}/jenkins.war")
node.set['jenkins_server']['version'] = version