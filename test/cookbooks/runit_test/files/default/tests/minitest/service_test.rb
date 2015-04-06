#
# Cookbook:: runit_test
# Minitest:: service
#
# Copyright 2012, Chef Software, Inc.
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

require File.expand_path('../support/helpers', __FILE__)

describe 'runit_test::service' do
  include Helpers::RunitTest
  MiniTest::Chef::Resources.register_resource(:runit_service)

  it 'creates a service with the defaults' do
    runit_service('plain-defaults').must_be_running
    file('/etc/service/plain-defaults/run').must_exist
    file('/etc/service/plain-defaults/log/run').must_exist
    file('/etc/init.d/plain-defaults').must_exist
    unless node['platform'] == 'gentoo'
      link('/etc/service/plain-defaults').must_exist.with(
        :link_type, :symbolic).and(:to, '/etc/sv/plain-defaults')
    end
  end

  it 'creates a service that doesnt use the svlog' do
    runit_service('no-svlog').must_be_running
    directory('/etc/sv/no-svlog/log').wont_exist
  end

  it 'creates a service that uses the default svlog' do
    regexp = %r{#!/bin/sh\nexec svlogd -tt /var/log/default-svlog}
    runit_service('default-svlog').must_be_running
    file('/etc/service/default-svlog/log/run').must_match(regexp)
  end

  it 'creates a service that has a check script' do
    runit_service('checker').must_be_running
    file('/etc/service/checker/check').must_exist
  end

  it 'creates a service that has a finish script' do
    runit_service('finisher').must_be_running
    file('/etc/service/finisher/finish').must_exist
  end

  it 'creates a service using sv_timeout' do
    runit_service('timer').must_be_running
  end

  it 'creates a service using sv_verbose' do
    runit_service('chatterbox').must_be_running
  end

  it 'creates a service that uses env files' do
    regexp = %r{\$PATH:/opt/chef/embedded/bin}
    runit_service('env-files').must_be_running
    file('/etc/service/env-files/env/PATH').must_match(regexp)
  end

  it 'creates a service that sets options for the templates' do
    runit_service('template-options').must_be_running
    file('/etc/service/template-options/run').must_match('# Options are delicious')
  end

  it 'creates a service that uses control signal files' do
    runit_service('control-signals').must_be_running
    file('/etc/service/control-signals/control/u').must_match(/control signal up/)
  end

  it 'creates a runsvdir service for a normal user' do
    regexp = %r{exec chpst -ufloyd runsvdir /home/floyd/service}
    runit_service('runsvdir-floyd').must_be_running
    file('/etc/service/runsvdir-floyd/run').must_match(regexp)
  end

  it 'creates a service running by a normal user in its runsvdir' do
    floyds_app = shell_out(
      "#{node['runit']['sv_bin']} status /home/floyd/service/floyds-app",
      :user => 'floyd',
      :cwd => '/home/floyd'
    )
    assert floyds_app.stdout.include?('run:')
    file('/home/floyd/service/floyds-app/run').must_exist.with(:owner, 'floyd')
    file('/home/floyd/service/floyds-app/log/run').must_exist.with(:owner, 'floyd')
    file('/etc/init.d/floyds-app').must_exist
    unless node['platform'] == 'gentoo'
      link('/home/floyd/service/floyds-app').must_exist.with(
        :link_type, :symbolic).and(:to, '/home/floyd/sv/floyds-app')
    end
  end

  it 'creates a service with differently named template files' do
    runit_service('yerba').must_be_running
  end

  it 'creates a service with differently named run script template' do
    runit_service('yerba-alt').must_be_running
  end

  it 'creates a service that should exist but be disabled' do
    file('/etc/sv/exist-disabled/run').must_exist
    link('/etc/service/exist-disabled').wont_exist unless node['platform'] == 'gentoo'
  end

  it 'can use templates from another cookbook' do
    runit_service('other-cookbook-templates').must_be_running
  end

  it 'creates a service that has its own run scripts' do
    skip 'RHEL platforms dont ship runit scripts' if node['platform_family'] == 'rhel' || node['platform_family'] == 'fedora'

    git_daemon = shell_out("#{node['runit']['sv_bin']} status /etc/service/git-daemon")
    assert git_daemon.stdout.include?('run:')
    link('/etc/service/git-daemon').must_exist.with(
      :link_type, :symbolic).and(:to, '/etc/sv/git-daemon')
  end
end
