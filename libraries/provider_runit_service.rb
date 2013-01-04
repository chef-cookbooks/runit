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

require 'chef/provider/service'
require 'chef/provider/link'
require 'chef/resource/link'
require 'chef/provider/directory'
require 'chef/resource/directory'
require 'chef/provider/template'
require 'chef/resource/template'
require 'chef/provider/file'
require 'chef/resource/file'
require 'chef/mixin/shell_out'
require 'chef/mixin/language'
include Chef::Mixin::ShellOut

class Chef
  class Provider
    class Service
      class Runit < Chef::Provider::Service

        def load_current_resource
          @current_resource = Chef::Resource::RunitService.new(new_resource.name)
          @current_resource.service_name(new_resource.service_name)

          Chef::Log.debug("Checking status of service #{new_resource.service_name}")

          @current_resource.running(running?)
          @current_resource.enabled(enabled?)
          @current_resource
        end

        def action_enable
          if @current_resource.enabled
            Chef::Log.debug("#{new_resource} already enabled - nothing to do")
          else
            converge_by("enable service #{new_resource}") do

              sv_dir = Chef::Resource::Directory.new(sv_dir_name)
              sv_dir.recursive(true)
              sv_dir.owner(new_resource.owner)
              sv_dir.group(new_resource.group)
              sv_dir.mode(00755)
              sv_dir.run_action(:create)

              run_script = Chef::Resource::Template.new(::File.join(sv_dir_name, 'run'))
              run_script.owner(new_resource.owner)
              run_script.group(new_resource.group)
              run_script.source("sv-#{new_resource.service_name}-run.erb")
              if new_resource.options.respond_to?(:has_key?)
                run_script.variables(:options => new_resource.options)
              end
              run_script.run_action(:create)

              if new_resource.log
                log_dir = Chef::Resource::Directory.new(::File.join(sv_dir_name, 'log'))
                log_dir.recursive(true)
                log_dir.owner(new_resource.owner)
                log_dir.group(new_resource.group)
                log_dir.mode(00755)
                log_dir.run_action(:create)

                if new_resource.default_logger
                  log_run_file = Chef::Resource::File.new(::File.join( sv_dir_name,
                                                                       'log',
                                                                       'run' ))
                  log_run_file.content(default_logger_content)
                  log_run_file.owner(new_resource.owner)
                  log_run_file.group(new_resource.group)
                  log_run_file.mode(00755)
                  log_run_file.run_action(:create)
                else
                  log_run_file = Chef::Resource::Template.new(::File.join( sv_dir_name,
                                                                           'log',
                                                                           'run' ))
                  log_run_file.owner(new_resource.owner)
                  log_run_file.group(new_resource.group)
                  log_run_file.mode(00755)
                  log_run_file.source("sv-#{new_resource.log_template_name}-log-run.erb")
                  if new_resource.options.respond_to?(:has_key?)
                    log_run_file.variables(:options => new_resource.options)
                  end
                  log_run_file.run_action(:create)
                end
              end

              unless new_resource.env.empty?
                env_dir = Chef::Resource::Directory.new(::File.join(sv_dir_name, 'env'))
                env_dir.mode(00755)
                env_dir.run_action(:create)

                new_resource.env.each do |var, value|
                  env_file = Chef::Resource::File.new(::File.join(sv_dir_name, 'env', 'var'))
                  env_file.content(value)
                  env_file.run_action(:create)
                end
              end

              if new_resource.finish_script
                finish_script_file = Chef::Resource::Template.new(::File.join(sv_dir_name, 'finish'))
                finish_script_file.owner(new_resource.owner)
                finish_script_file.group(new_resource.group)
                finish_script_file.mode(00755)
                finish_script_file.source("sv-#{new_resource.finish_script_template_name}-finish.erb")
                if new_resource.options.respond_to?(:has_key?)
                  finish_script_file.variables(:options => new_resource.options)
                end
                finish_script_file.run_action(:create)
              end

              unless new_resource.control.empty?
                control_dir = Chef::Resource::Directory.new(::File.join(sv_dir_name, 'control'))
                control_dir.run_action(:create)

                new_resource.control.each do |signal|
                  control_signal_file = Chef::Resource::Template.new(::File.join( sv_dir_name,
                                                                                  'control',
                                                                                  signal))
                  control_signal_file.owner(new_resource.owner)
                  control_signal_file.group(new_resource.group)
                  control_signal_file.source("sv-#{new_resource.control_template_names[signal]}-#{signal}.erb")
                  if new_resource.options.respond_to?(:has_key?)
                    control_signal_file.variables(:options => new_resource.options)
                  end
                  control_signal_file.run_action(:create)
                end
              end

              if node['platform'] == 'debian'
                lsb_init = Chef::Resource::Template.new(::File.join( 'etc',
                                                                     'init.d',
                                                                     new_resource.service_name))
                lsb_init.owner('root')
                lsb_init.group('root')
                lsb_init.mode(00755)
                lsb_init.cookbook('runit')
                lsb_init.source('init.d.erb')
                lsb_init.variables(:options => new_resource.options)
                lsb_init.run_action(:create)
              else
                lsb_init = Chef::Resource::Link.new(::File.join( 'etc',
                                                                 'init.d',
                                                                 new_resource.service_name))
                lsb_init.to(node['runit']['sv_bin'])
                lsb_init.run_action(:create)
              end

              unless node['platform'] == 'gentoo'
                service_link = Chef::Resource::Link.new(::File.join(service_dir_name))
                service_link.to(sv_dir_name)
                service_link.run_action(:create)
              end
            end
          end
        end

        def action_start
          if @current_resource.running
            Chef::Log.debug("#{new_resource} already running - nothing to do")
          else
            converge_by("start service #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} start #{service_dir_name}")
              Chef::Log.info("#{new_resource} started")
              new_resource.updated_by_last_action(true)
            end
          end
        end

        def action_up
          if @current_resource.running
            Chef::Log.debug("#{new_resource} already running - nothing to do")
          else
            converge_by("start service #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} up #{service_dir_name}")
              Chef::Log.info("#{new_resource} started")
              new_resource.updated_by_last_action(true)
            end
          end
        end

        def action_disable
          if @current_resource.enabled
            converge_by("down #{new_resource} and remove symlink") do

              shell_out!("#{node['runit']['sv_bin']} down #{service_dir_name}")

              Chef::Log.debug("#{new_resource} down")

              FileUtils.rm(service_dir_name)

              Chef::Log.debug("#{new_resource} service symlink removed")
              Chef::Log.info("#{new_resource} disabled")
            end
          else
            Chef::Log.debug("#{new_resource} not enabled - nothing to do")
          end
        end

        def action_stop
          if @current_resource.running
            converge_by("stop service #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} stop #{service_dir_name}")
              Chef::Log.info("#{new_resource} stopped")
              new_resource.updated_by_last_action(true)
            end
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        def action_down
          if @current_resource.running
            converge_by("down service #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} down #{service_dir_name}")
              Chef::Log.info("#{new_resource} down")
              new_resource.updated_by_last_action(true)
            end
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        def action_restart
          if @current_resource.running
            converge_by("restart service #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} restart #{service_dir_name}")
              Chef::Log.info("#{new_resource} was not running, sent restart")
              new_resource.updated_by_last_action(true)
            end
          else
            converge_by("start service #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} up #{service_dir_name}")
              Chef::Log.info("#{new_resource} was not running, sent 'up' to start")
              new_resource.updated_by_last_action(true)
            end
          end
        end

        def action_reload
          if @current_resource.running
            shell_out!("#{node['runit']['sv_bin']} force-reload #{service_dir_name}")
            new_resource.updated_by_last_action(true)
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        def action_once
          if @current_resource.running
            Chef::Log.debug("#{new_resource} is running - nothing to do")
          else
            converge_by("start service #{new_resource} once") do
              shell_out!("#{node['runit']['sv_bin']} once #{service_dir_name}")
              Chef::Log.info("#{new_resource} started once")
              new_resource.updated_by_last_action(true)
            end
          end
        end

        def action_cont
          if @current_resource.running
            Chef::Log.debug("#{new_resource} is running - nothing to do")
          else
            converge_by("continue service #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} cont #{service_dir_name}")
              Chef::Log.info("#{new_resource} continued")
              new_resource.updated_by_last_action(true)
            end
          end
        end

        def action_hup
          if @current_resource.running
            converge_by("send hup to #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} hup #{service_dir_name}")
              Chef::Log.info("#{new_resource} sent hup")
              new_resource.updated_by_last_action(true)
            end
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        def action_int
          if @current_resource.running
            converge_by("send int to #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} int #{service_dir_name}")
              Chef::Log.info("#{new_resource} sent int")
              new_resource.updated_by_last_action(true)
            end
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        def action_term
          if @current_resource.running
            converge_by("send term to #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} term #{service_dir_name}")
              Chef::Log.info("#{new_resource} sent term")
              new_resource.updated_by_last_action(true)
            end
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        def action_kill
          if @current_resource.running
            converge_by("send kill to #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} kill #{service_dir_name}")
              Chef::Log.info("#{new_resource} sent kill")
              new_resource.updated_by_last_action(true)
            end
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        def action_usr1
          if @current_resource.running
            converge_by("send usr1 to #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} 1 #{service_dir_name}")
              Chef::Log.info("#{new_resource} sent usr1")
              new_resource.updated_by_last_action(true)
            end
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        def action_usr2
          if @current_resource.running
            converge_by("send usr2 to #{new_resource}") do
              shell_out!("#{node['runit']['sv_bin']} 2 #{service_dir_name}")
              Chef::Log.info("#{new_resource} sent usr2")
              new_resource.updated_by_last_action(true)
            end
          else
            Chef::Log.debug("#{new_resource} not running - nothing to do")
          end
        end

        private
        def running?
          cmd = shell_out("#{node['runit']['sv_bin']} status #{new_resource.service_name}")
          (cmd.stdout =~ /^run:/ && cmd.exitstatus == 0)
        end

        def enabled?
          ::File.exists?(::File.join(service_dir_name, "run"))
        end

        def sv_dir_name
          ::File.join(new_resource.sv_dir, new_resource.service_name)
        end

        def service_dir_name
          ::File.join(new_resource.service_dir, new_resource.service_name)
        end

        def default_logger_content
          content <<-EOF
#!/bin/sh
exec svlogd -tt /var/log/#{new_resource.service_name}
EOF
        end
      end
    end
  end
end
