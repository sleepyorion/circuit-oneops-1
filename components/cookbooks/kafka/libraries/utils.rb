#
# Cookbook Name:: bcpc
# Library:: utils
#
# Copyright 2013, Bloomberg Finance L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'openssl'
require 'thread'


#
# Restarting of hadoop processes need to be controlled in a way that all the nodes
# are not down at the sametime, the consequence of which will impact users. In order
# to achieve this, nodes need to acquire a lock before restarting the process of interest.
# This function is to acquire the lock which is a znode in zookeeper. The znode name is the name  
# of the service to be restarted for e.g "hadoop-hdfs-datanode" and is located by default at "/".
# The input parameters are service name along with the ZK path (znode name), string of zookeeper
# servers ("zk_host1:port,sk_host2:port"), and the fqdn of the node acquiring the lock
# Return value : true or false
#
def acquire_restart_lock(znode_path, zk_hosts,node_name)
  require 'rubygems'
  require 'zookeeper'
  lock_acquired = false
  zk = nil
  begin
    zk = Zookeeper.new(zk_hosts)
    if !zk.connected?
      raise "acquire_restart_lock : unable to connect to ZooKeeper quorum #{zk_hosts}"
    end
    ret = zk.create(:path => znode_path, :data => node_name)
    if ret[:rc] == 0
      lock_acquired = true
    end
  rescue Exception => e
    puts e.message
  ensure
    if !zk.nil?
      zk.close unless zk.closed? 
    end
  end
  return lock_acquired
end

#
# This function is to check whether the lock to restart a particular service is held by a node.
# The input parameters are the path to the znode used to restart a hadoop service, a string containing the 
# host port values of the ZooKeeper nodes "host1:port, host2:port" and the fqdn of the host
# Return value : true or false
#
def my_restart_lock?(znode_path, zk_hosts,node_name)
  require 'rubygems'
  require 'zookeeper'
  my_lock = false
  zk = nil
  begin
    zk = Zookeeper.new(zk_hosts)
    if !zk.connected?
      raise "my_restart_lock?: unable to connect to ZooKeeper quorum #{zk_hosts}"
    end
    ret = zk.get(:path => znode_path)
    val = ret[:data]
    if val == node_name
      my_lock = true
    end
  rescue Exception => e
    puts e.message
  ensure
    if !zk.nil?
      zk.close unless zk.closed?
    end
  end
  return my_lock
end

#
# Function to release the lock held by the node to restart a particular hadoop service
# The input parameters are the name of the path to znode which was used to lock for restarting service,
# string containing the zookeeper host and port ("host1:port,host2:port") and the fqdn
# of the node trying to release the lock.
# Return value : true or false based on whether the lock release was successful or not
#
def rel_restart_lock(znode_path, zk_hosts,node_name)
  require 'rubygems'
  require 'zookeeper'
  lock_released = false
  zk = nil
  begin
    zk = Zookeeper.new(zk_hosts)
    if !zk.connected?
      raise "rel_restart_lock : unable to connect to ZooKeeper quorum #{zk_hosts}"
    end
    if my_restart_lock?(znode_path, zk_hosts, node_name)
      ret = zk.delete(:path => znode_path)
    else
      raise "rel_restart_lock : node who is not the owner is trying to release the lock"
    end
    if ret[:rc] == 0
      lock_released = true
    end
  rescue Exception => e
    puts e.message
  ensure
    if !zk.nil?
      zk.close unless zk.closed? 
    end
  end
  return lock_released
end

#
# Function to get the node name which is holding a particular service restart lock
# Input parameters: The path to the znode (lock) and the string of zookeeper hosts:port 
# Return value    : The fqdn of the node which created the znode to restart or nil
#
def get_restart_lock_holder(znode_path, zk_hosts)
  require 'rubygems'
  require 'zookeeper'
  begin
    zk = Zookeeper.new(zk_hosts)
    if !zk.connected?
      raise "get_restart_lock_holder : unable to connect to ZooKeeper quorum #{zk_hosts}"
    end
    ret = zk.get(:path => znode_path)
    if ret[:rc] == 0
      val = ret[:data]
    end
  rescue Exception => e
    puts e.message
  ensure
    if !zk.nil?
      zk.close unless zk.closed?
    end
  end
  return val
end
#
# Function to generate the full path of znode which will be used to create a restart lock znode
# Input paramaters: The path in ZK where znodes are created for the retart locks and the lock name
# Return value    : Fully formed path which can be used to create the znode 
#
def format_restart_lock_path(root, lock_name)
  begin
    if root.nil?
      return "/#{lock_name}"
    elsif root == "/"
      return "/#{lock_name}"
    else
      return "#{root}/#{lock_name}"
    end
  end
end
#
# Function to identify start time of a process
# Input paramater: string to identify the process through pgrep command
# Returned value : The starttime for the process. If multiple instances are returned from pgrep
# command, time returned will be the earliest time of all the instances
#
def process_start_time(process_identifier)
  require 'time'
  begin
    target_process_pid = `pgrep -f #{process_identifier}`
    if target_process_pid == ""
      return nil
    else
      target_process_pid_arr = Array.new()
      target_process_pid_arr = target_process_pid.split("\n").map{|pid| (`ps --no-header -o start_time #{pid}`).strip}
      start_time_arr = Array.new()
      target_process_pid_arr.each do |t|
        if t != ""
          start_time_arr.push(Time.parse(t))
        end
      end
      return start_time_arr.sort.first.to_s
    end
  end
end
#
# Function to check whether a process was started manually after restart of the process failed during prev chef client run
# Input paramaters : Last restart failure time, string to identify the process
# Returned value   : true or false
#
def process_restarted_after_failure?(restart_failure_time, process_identifier)
  require 'time'
  begin
    start_time = process_start_time(process_identifier)
    if start_time.nil?
      return false
    elsif Time.parse(restart_failure_time).to_i < Time.parse(start_time).to_i
      Chef::Log.info("#{process_identifier} seem to be started at #{start_time} after last restart failure at #{restart_failure_time}") 
      return true
    else
      return false
    end
  end
end

def java_version
    ver_str = `java -version 2>&1 | grep "java version"`
    Chef::Log.info "Java version string: #{ver_str}"
    # Strip the 'java version ".."' from the string
    (!ver_str.nil? && !ver_str.empty?) ? ver_str.gsub(/[java version *,",\n]/, '') : `Chef::Log.error "Java version is empty. Cannot Proceed further..."`
end