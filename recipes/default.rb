#
# Cookbook:: runit
# Recipe:: default
#
# Copyright:: 2008-2016, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

service 'runit' do
  action :nothing
end

execute 'start-runsvdir' do # ~FC004
  command '/etc/init.d/runit-start start'
  action :nothing
end

case node['platform_family']
when 'rhel', 'amazon'

  # add the necessary repos unless prefer_local_yum is set
  unless node['runit']['prefer_local_yum']
    include_recipe 'yum-epel' if node['platform_version'].to_i < 7

    packagecloud_repo 'imeyer/runit' do
      force_os 'rhel' if platform?('oracle', 'amazon') # ~FC024
      force_dist '6' if platform?('amazon')
      type 'rpm' if platform?('amazon')
    end
  end

  package 'runit'

  service 'runsvdir-start' do
    action [:start, :enable]
    only_if { node['platform_version'].to_i == 7 }
  end

when 'debian'
  # debian 9+ ship with runit-systemd which includes only what you need for process supervision and not
  # what is necessary for running runit as pid 1, which we don't care about.
  pkg_name = platform?('debian') && node['platform_version'].to_i >= 9 ? 'runit-systemd' : 'runit'

  package pkg_name do
    action :install
    response_file 'runit.seed'
  end
end
