#
# Cookbook Name:: runit_test
# Recipe:: lwrp
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

# Create a service with all the fixin's
runit_service "potpie"

# Create a service that doesn't use the svlog
runit_service "not-logging" do
  log false
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

