#
# Cookbook Name:: runit_test
# Recipe:: service
#
# Copyright 2012, Chef Software, Inc.
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

include_recipe 'runit::default'

link '/usr/local/bin/sv' do
  to '/usr/bin/sv'
end

package 'socat'

package 'netcat' do
  package_name 'nc' if platform_family?('rhel', 'fedora')
end

package 'lsof' do
  package_name 'lsof' if platform_family?('rhel', 'fedora')
end

# Create a normal user to run services later
group 'floyd'

user 'floyd' do
  comment 'Floyd the App Runner'
  gid 'floyd'
  shell '/bin/bash'
  home '/home/floyd'
  manage_home true
  supports manage_home: true
end

%w(sv service).each do |dir|
  directory "/home/floyd/#{dir}" do
    owner 'floyd'
    group 'floyd'
    recursive true
  end
end

# drop off environment files outside of the runit_service resources
# so we can test manage_env_dir behavior
%w(plain-defaults env-files).each do |svc|
  directory "#{node['runit']['sv_dir']}/#{svc}/env" do
    recursive true
    action :nothing
  end.run_action(:create)

  file "#{node['runit']['sv_dir']}/#{svc}/env/ZAP_TEST" do
    content '1'
    action :nothing
  end.run_action(:create)
end

# Create a service with all the fixin's
runit_service 'plain-defaults'

# Create a service that doesn't use the svlog
runit_service 'no-svlog' do
  log false
end

# Create a service that uses the default svlog
runit_service 'default-svlog' do
  default_logger true
  log_size 10_000 # smallish 10k
  log_num 12
  log_processor 'gzip'
end

# Create a service that has a check script
runit_service 'checker' do
  check true
end

# Create a service that has a finish script
runit_service 'finisher' do
  finish true
end

# Create a service that uses env files
runit_service 'env-files' do
  env('PATH' => '$PATH:/opt/chef/embedded/bin')
end

# Create a service that sets options for the templates
runit_service 'template-options' do
  options(raspberry: 'delicious')
end

# Create a service that uses control signal files
runit_service 'control-signals' do
  control ['u']
end

# Create a runsvdir service for a normal user
runit_service 'runsvdir-floyd'

# Create a service with different timeout
runit_service 'timer' do
  sv_timeout 4
  check true
end

# Create a service with verbose enabled
runit_service 'chatterbox' do
  sv_verbose true
end

# # Create a service running by a normal user in its runsvdir
runit_service 'floyds-app' do
  sv_dir '/home/floyd/sv'
  service_dir '/home/floyd/service'
  owner 'floyd'
  group 'floyd'
end

# Create a service with differently named template files
runit_service 'yerba' do
  log_template_name 'yerba-matte'
  check_script_template_name 'yerba-matte'
  finish_script_template_name 'yerba-matte'
  log_dir '/var/log/yerba-matte'
end

# Create a service with differently named template file, using default logger with non-default log_dir
runit_service 'yerba-alt' do
  run_template_name 'calabash'
  default_logger true
  log_dir '/var/log/yerba/matte/'
end

# Create a service with a template sourced from another cookbook
runit_service 'ayahuasca' do
  run_template_name 'ayahuasca'
  default_logger true
  log_dir '/opt/ayahuasca/log'
  cookbook 'runit_other_test'
end

# Note: this won't update the run script for the above due to
# http://tickets.chef.io/browse/COOK-2353
# runit_service 'the other name for yerba-alt' do
#   service_name 'yerba-alt'
#   default_logger true
# end

runit_service 'exist-disabled' do
  action [:create, :disable]
end

# unless platform_family?('rhel', 'fedora')
#   # Create a service that has a package with its own service directory
#   package 'git-daemon-run'

#   runit_service 'git-daemon' do
#     sv_templates false
#   end
# end

# Despite waiting for runit to create supervise/ok, sometimes services
# are supervised, but not actually fully started
ruby_block 'sleep 5s to allow services to be fully started' do
  block do
    sleep 5
  end
end

# # Notify the plain defaults service as a normal service resource
file '/tmp/notifier' do
  content Time.now.to_s
  notifies :restart, 'service[plain-defaults]', :immediately
end

file '/tmp/notifier-2' do
  content Time.now.to_s
  notifies :restart, 'runit_service[plain-defaults]', :immediately
end

# # Test for COOK-2867
# link '/etc/init.d/cook-2867' do
#   to '/usr/bin/sv'
# end

# runit_service 'cook-2867' do
#   default_logger true
# end

# create a service using an alternate sv binary
runit_service 'alternative-sv-bin' do
  sv_bin '/usr/local/bin/sv'
end

runit_service 'downed-service-6702' do
  start_down true
end

runit_service 'un-downed-service' do
  start_down true
end

runit_service 'un-downed-service remove down' do
  service_name 'un-downed-service'
  log_template_name 'un-downed-service'
  run_template_name 'un-downed-service'
  start_down false
end

runit_service 'un-downed-service-deleted' do
  start_down true
end

runit_service 'un-downed-service-deleted remove down' do
  service_name 'un-downed-service-deleted'
  log_template_name 'un-downed-service-deleted'
  run_template_name 'un-downed-service-deleted'
  start_down false
  delete_downfile true
end

# Use a service with all the fixin's to ensure all actions are
# available and working

actions = (runit_service('plain-defaults').allowed_actions - [:enable, :disable]) + [:disable, :enable]

actions.each do |test_action|
  runit_service 'plain-defaults' do
    action test_action
  end
end
