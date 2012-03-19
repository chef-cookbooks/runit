#
# Cookbook Name:: runit
# Provider:: service
#
# Copyright 2011, Joshua Timberman
# Copyright 2011, Opscode, Inc.
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

require 'chef/mixin/command'
require 'chef/mixin/language'
include Chef::Mixin::Command

action :enable do
  new_resource.directory("#{node['runit']['sv_dir']}/#{new_resource.service_name}") unless new_resource.directory
  directory new_resource.directory do
    owner new_resource.owner
    group new_resource.group
    mode 0755
  end

  if new_resource.template
    template "#{new_resource.directory}/run" do
      source "sv-#{new_resource.service_name}-run.erb"
      cookbook new_resource.cookbook if new_resource.cookbook
      owner new_resource.owner
      group new_resource.group
      mode 0755
      variables :variables => new_resource.variables unless new_resource.variables.empty?
    end
    if new_resource.log
      directory "#{new_resource.directory}/log" do
        owner new_resource.owner
        group new_resource.group
        mode 0755
      end
      directory "#{new_resource.directory}/log/main" do
        owner new_resource.owner
        group new_resource.group
        mode 0755
      end
      template "#{new_resource.directory}/log/run" do
        source "sv-#{new_resource.service_name}-log-run.erb"
        cookbook new_resource.cookbook if new_resource.cookbook
        owner new_resource.owner
        group new_resource.group
        mode 0755
        variables :variables => new_resource.variables unless new_resource.variables.empty?
      end
    end
    if new_resource.finish
      template "#{new_resource.directory}/finish" do
        source "sv-#{new_resource.service_name}-finish.erb"
        cookbook new_resource.cookbook if new_resource.cookbook
        owner new_resource.owner
        group new_resource.group
        mode 0755
        variables :variables => new_resource.variables unless new_resource.variables.empty?
      end
    end
  end

  unless new_resource.env.empty?
    directory "#{new_resource.directory}/env" do
      owner new_resource.owner
      group new_resource.group
      mode 0755
    end
    new_resource.env.each do |var, value|
      file "#{new_resource.directory}/env/#{var}" do
        content value
        owner new_resource.owner
        group new_resource.group
        mode 0644
      end
    end
  end

  unless new_resource.control.empty?
    directory "#{new_resource.directory}/control" do
      owner new_resource.owner
      group new_resource.group
      mode 0755
      action :create
    end

    new_resource.control.each do |signal|
      template "#{new_resource.directory}/control/#{signal}" do
        source "sv-#{new_resource.template}-control-#{signal}.erb"
        cookbook new_resource.cookbook if new_resource.cookbook
        owner new_resource.owner
        group new_resource.group
        mode 0755
        variables :variables => new_resource.variables unless new_resource.variables.empty?
      end
    end
  end

  link "#{node['runit']['service_dir']}/#{new_resource.service_name}" do
    to new_resource.directory
  end unless node['platform'] == "gentoo"

  link "/etc/init.d/#{new_resource.service_name}" do
    to node['runit']['sv_bin']
  end

  ruby_block "supervise_#{new_resource.service_name}_sleep" do
    block do
      Chef::Log.debug("Waiting until named pipe #{new_resource.directory}/#{new_resource.service_name}/supervise/ok exists.")
      (1..10).each {|i| sleep 1 unless ::FileTest.pipe?("#{new_resource.directory}/#{new_resource.service_name}/supervise/ok") }
    end
    not_if { FileTest.pipe?("#{new_resource.directory}/#{new_resource.service_name}/supervise/ok") }
  end unless running?
end

action :start do
  unless running?
    execute "#{node['runit']['sv_bin']} start #{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :up do
  unless running?
    execute "#{node['runit']['sv_bin']} up #{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :disable do
  if @svc.enabled
    execute "#{node['runit']['sv_bin']} down #{new_resource.service_name}"

    link "#{node['runit']['service_dir']}/#{new_resource.service_name}" do
      action :delete
    end
    new_resource.updated_by_last_action(true)
  end
end

action :stop do
  if running?
    execute "#{node['runit']['sv_bin']} stop #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :down do
  if running?
    execute "#{node['runit']['sv_bin']} down #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :restart do
  if running?
    execute "#{node['runit']['sv_bin']} restart #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :reload do
  if running?
    execute "#{node['runit']['sv_bin']} force-reload #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :once do
  if running?
    execute "#{node['runit']['sv_bin']} once #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :cont do
  if running?
    execute "#{node['runit']['sv_bin']} cont #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :hup do
  if running?
    execute "#{node['runit']['sv_bin']} hup #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :int do
  if running?
    execute "#{node['runit']['sv_bin']} int #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :term do
  if running?
    execute "#{node['runit']['sv_bin']} term #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

action :kill do
  if running?
    execute "#{node['runit']['sv_bin']} kill #{node['runit']['service_dir']}/#{new_resource.service_name}"
    new_resource.updated_by_last_action(true)
  end
end

private
def running?
  shell_out("#{node['runit']['sv_bin']} status #{new_resource.service_name}").stdout =~ /^run:/
end
