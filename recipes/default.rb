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

execute 'start-runsvdir' do
  command '/etc/init.d/runit-start start'
  action :nothing
end

case node['platform_family']
when 'rhel'

  # add the necessary repos unless prefer_local_yum is set
  unless node['runit']['prefer_local_yum']
    include_recipe 'yum-epel' if node['platform_version'].to_i < 7

    packagecloud_repo 'imeyer/runit' do
      force_os 'rhel' if node['platform'].eql?('oracle')
    end
  end

  package 'runit'

  service 'runsvdir-start' do
    action [:start, :enable]
    only_if { node['platform_version'].to_i == 7 }
  end

when 'debian'
  package 'runit' do
    action :install
    response_file 'runit.seed'
  end
end
