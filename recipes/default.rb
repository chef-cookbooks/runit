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
case node['platform_family']
when 'rhel', 'amazon'

  # add the necessary repos unless prefer_local_yum is set
  unless node['runit']['prefer_local_yum']
    include_recipe 'yum-epel' if node['platform_version'].to_i < 7

    packagecloud_repo 'imeyer/runit' do
      force_os 'rhel' if platform?('oracle', 'amazon') # ~FC024
      force_dist '6' if platform?('amazon')
      force_dist '7' if platform?('amazon') && node['platform_version'].to_i == 2
      type 'rpm' if platform?('amazon')
    end
  end

  package 'runit'
when 'debian'
  # debian 9+ ships with runit-systemd which includes only what you need for process supervision and not
  # what is necessary for running runit as pid 1, which we don't care about.
  pv = node['platform_version']
  pkg_name = if (platform?('debian') && pv.to_i >= 9) || \
                (platform?('ubuntu') && Gem::Version.new(pv) >= Gem::Version.new('17.10'))
               'runit-systemd'
             else
               'runit'
             end

  package pkg_name do
    action :install
    response_file 'runit.seed'
  end
else
  raise 'The cookbook only supports Debian/RHEL based Linux distributions. If you believe further platform support is possible please open a pull request.'
end

# we need to make sure we start the runit service so that runit services can be started up at boot
# or when they fail
plat_specific_sv_name = case node['platform_family']
                        when 'debian'
                          if platform?('ubuntu') && node['platform_version'].to_f < 16.04
                            'runsvdir'
                          else
                            'runit'
                          end
                        when 'rhel', 'amazon'
                          if node['platform_version'].to_i >= 7 && !platform?('amazon')
                            'runsvdir-start'
                          elsif node['platform_version'].to_i == 2 && platform?('amazon')
                            'runsvdir-start'
                          else
                            'runsvdir'
                          end
                        else
                          'runsvdir'
                        end

service plat_specific_sv_name do
  action [:start, :enable]
  # this might seem crazy, but RHEL 6 is in fact Upstart and the runit service is upstart there
  provider Chef::Provider::Service::Upstart if (platform?('amazon') && node['platform_version'].to_i != 2) || (platform_family?('rhel') && node['platform_version'].to_i == 6)
  not_if { platform?('debian') && node['platform_version'].to_i < 8 } # there's no init script on debian 7...for reasons
end
