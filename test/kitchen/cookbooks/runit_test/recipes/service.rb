#
# Cookbook Name:: runit_test
# Recipe:: service
#
# Copyright 2012, Opscode, Inc.
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

include_recipe "runit::default"

# Create a normal user to run services later
group "floyd"

user "floyd" do
  comment "Floyd the App Runner"
  gid "floyd"
  shell "/bin/bash"
  home "/home/floyd"
  manage_home true
  supports :manage_home => true
end

# Create a service with all the fixin's
runit_service "potpie"

# Create a service that doesn't use the svlog
runit_service "not-logging" do
  log false
end

# Create a service that uses the default svlog
runit_service "beaver" do
  default_logger true
end

# Create a service that has a finish script
runit_service "kombat" do
  finish true
end

# Create a service that uses env files
runit_service "greenpeace" do
  env({"PATH" => "$PATH:/opt/chef/embedded/bin"})
end

# Create a service that sets options for the templates
runit_service "berries" do
  options({:raspberry => "delicious"})
end

# Create a service that uses control signal files
runit_service "milkshake" do
  control ["u"]
end

# Create a runsvdir service for a normal user
runit_service "runsvdir-floyd" do
  service_dir "/home/floyd/service"
end

# Create a service running by a normal user in its runsvdir
runit_service "floyds-app" do
  owner "floyd"
  group "floyd"
end

# Create a service with differently named template files
runit_service "yerba" do
  log_template_name "yerba-matte"
  finish_script_template_name "yerba-matte"
end

# Create a service with runit as the provider
service "cashews" do
  provider Chef::Provider::Service::Runit
end

# Create a service that will be down
runit_service "abbey" do
  action :down
end

# Create a service that should exist but be disabled
runit_service "pug"

log "Created the pug service, now disable it"

runit_service "pug" do
  action :disable
end
