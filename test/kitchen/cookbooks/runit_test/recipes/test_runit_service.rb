#
# Cookbook Name:: runit
# Recipe:: test_runit_service
#
# Copyright 2013, Heavy Water Operations, LLC.
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

package "memcached"

service "memcached" do
  provider Chef::Provider::Service::Init
  action [:disable, :stop]
end

runit_service "memcached" do
  options(
    :user => "memcache",
    :memory => 42,
    :port => 11211
  )
end
