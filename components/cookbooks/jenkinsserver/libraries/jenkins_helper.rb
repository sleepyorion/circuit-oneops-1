require 'mixlib/shellout'

module JenkinsHelper
	def reload_start_jenkins
		["reread","update","start jenkins_server"].each { |ops|
			cmd = Mixlib::ShellOut.new("supervisorctl #{ops}")
			res = cmd.run_command
			puts cmd.stdout
			puts cmd.stderr
			if res.exitstatus != 0
				puts "***FAULT:FATAL=Failed to run cmd: supervisorctl #{ops}"
				e = Exception.new("no backtrace")
				e.set_backtrace("")
				raise e
			end
		}
	end

	def get_jenkins_version(jar_path)
		version = nil
		cmd = Mixlib::ShellOut.new("java -jar #{jar_path} --version")
		begin
			res = cmd.run_command
			if res.exitstatus != 0
				puts "***FAULT:FATAL=Failed to run cmd: java -jar #{jar_path} --version"
				e = Exception.new("no backtrace")
				e.set_backtrace("")
				raise e
			else
				version = res.stdout
			end
		rescue Exception => e
			puts "***FAULT:FATAL=Failed to run cmd: java -jar #{jar_path} --version"
			raise e
		end
		version
	end

	def configure_initial_admin(jenkins_home)
		version = get_jenkins_version("#{jenkins_home}/jenkins.war")
	end
end

