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

        def initialize(*args)
          super
          @sv_dir = nil
          @run_script = nil
          @log_dir = nil
          @log_main_dir = nil
          @default_log_dir = nil
          @log_run_script = nil
          @env_dir = nil
          @env_files = nil
          @finish_script = nil
          @control_dir = nil
          @control_signal_files = nil
          @lsb_init = nil
          @service_link = nil
          @new_resource.supports[:status] = true
        end

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

              if new_resource.sv_templates
                Chef::Log.debug("Creating sv_dir for #{new_resource.service_name}")
                sv_dir.run_action(:create)
                Chef::Log.debug("Creating run_script for #{new_resource.service_name}")
                run_script.run_action(:create)

                if new_resource.log
                  Chef::Log.debug("Setting up svlog for #{new_resource.service_name}")
                  log_dir.run_action(:create)
                  log_main_dir.run_action(:create)
                  default_log_dir.run_action(:create) if new_resource.default_logger
                  log_run_script.run_action(:create)
                else
                  Chef::Log.debug("log not specified for #{new_resource.service_name}, continuing")
                end

                unless new_resource.env.empty?
                  Chef::Log.debug("Setting up environment files for #{new_resource.service_name}")
                  env_dir.run_action(:create)
                  env_files.each {|file| file.run_action(:create)}
                else
                  Chef::Log.debug("Environment not specified for #{new_resource.service_name}, continuing")

                end

                if new_resource.finish
                  Chef::Log.debug("Creating finish script for #{new_resource.service_name}")
                  finish_script.run_action(:create)
                else
                  Chef::Log.debug("Finish script not specified for #{new_resource.service_name}, continuing")
                end

                unless new_resource.control.empty?
                  Chef::Log.debug("Creating control signal scripts for #{new_resource.service_name}")
                  control_dir.run_action(:create)
                  control_signal_files.each {|file| file.run_action(:create)}
                else
                  Chef::Log.debug("Control signals not specified for #{new_resource.service_name}, continuing")
                end
              end

              Chef::Log.debug("Creating lsb_init compatible interface #{new_resource.service_name}")
              lsb_init.run_action(:create)

              unless node['platform'] == 'gentoo'
                Chef::Log.debug("Creating symlink in service_dir for #{new_resource.service_name}")
                service_link.run_action(:create)
              end

              Chef::Log.debug("waiting until named pipe #{service_dir_name}/supervise/ok exists.")
              until ::FileTest.pipe?("#{service_dir_name}/supervise/ok") do
                sleep 1
                Chef::Log.debug(".")
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

              shell_out("#{node['runit']['sv_bin']} down #{service_dir_name}")

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

        def sv_dir
          return @sv_dir unless @sv_dir.nil?
          @sv_dir = Chef::Resource::Directory.new(sv_dir_name, run_context)
          @sv_dir.recursive(true)
          @sv_dir.owner(new_resource.owner)
          @sv_dir.group(new_resource.group)
          @sv_dir.mode(00755)
          @sv_dir
        end

        def run_script
          return @run_script unless @run_script.nil?
          @run_script = Chef::Resource::Template.new(::File.join(sv_dir_name, 'run'), run_context)
          @run_script.owner(new_resource.owner)
          @run_script.group(new_resource.group)
          @run_script.source("sv-#{new_resource.service_name}-run.erb")
          @run_script.cookbook(template_cookbook)
          @run_script.mode(00755)
          if new_resource.options.respond_to?(:has_key?)
            @run_script.variables(:options => new_resource.options)
          end
          @run_script
        end

        def log_dir
          return @log_dir unless @log_dir.nil?
          @log_dir = Chef::Resource::Directory.new(::File.join(sv_dir_name, 'log'), run_context)
          @log_dir.recursive(true)
          @log_dir.owner(new_resource.owner)
          @log_dir.group(new_resource.group)
          @log_dir.mode(00755)
          @log_dir
        end

        def log_main_dir
          return @log_main_dir unless @log_main_dir.nil?
          @log_main_dir = Chef::Resource::Directory.new(::File.join(sv_dir_name, 'log', 'main'), run_context)
          @log_main_dir.recursive(true)
          @log_main_dir.owner(new_resource.owner)
          @log_main_dir.group(new_resource.group)
          @log_main_dir.mode(00755)
          @log_main_dir
        end

        def default_log_dir
          return @default_log_dir unless @default_log_dir.nil?
          @default_log_dir = Chef::Resource::Directory.new(::File.join("/var/log/#{new_resource.service_name}"), run_context)
          @default_log_dir.recursive(true)
          @default_log_dir.owner(new_resource.owner)
          @default_log_dir.group(new_resource.group)
          @default_log_dir.mode(00755)
          @default_log_dir
        end

        def log_run_script
          return @log_run_script unless @log_run_script.nil?
          if new_resource.default_logger
            @log_run_script = Chef::Resource::File.new(::File.join( sv_dir_name,
                                                                    'log',
                                                                    'run' ),
                                                       run_context)
            @log_run_script.content(default_logger_content)
            @log_run_script.owner(new_resource.owner)
            @log_run_script.group(new_resource.group)
            @log_run_script.mode(00755)
          else
            @log_run_script = Chef::Resource::Template.new(::File.join( sv_dir_name,
                                                                        'log',
                                                                        'run' ),
                                                            run_context)
            @log_run_script.owner(new_resource.owner)
            @log_run_script.group(new_resource.group)
            @log_run_script.mode(00755)
            @log_run_script.source("sv-#{new_resource.log_template_name}-log-run.erb")
            @log_run_script.cookbook(template_cookbook)
            if new_resource.options.respond_to?(:has_key?)
              @log_run_script.variables(:options => new_resource.options)
            end
          end
          @log_run_script
        end

        def env_dir
          return @env_dir unless @env_dir.nil?
          @env_dir = Chef::Resource::Directory.new(::File.join(sv_dir_name, 'env'), run_context)
          @env_dir.owner(new_resource.owner)
          @env_dir.group(new_resource.group)
          @env_dir.mode(00755)
          @env_dir
        end

        def env_files
          return @env_files unless @env_files.nil?
          @env_files = new_resource.env.map do |var, value|
            env_file = Chef::Resource::File.new(::File.join(sv_dir_name, 'env', var), run_context)
            env_file.owner(new_resource.owner)
            env_file.group(new_resource.group)
            env_file.content(value)
            env_file
          end
          @env_files
        end

        def finish_script
          return @finish_script unless @finish_script.nil?
          @finish_script = Chef::Resource::Template.new(::File.join(sv_dir_name, 'finish'), run_context)
          @finish_script.owner(new_resource.owner)
          @finish_script.group(new_resource.group)
          @finish_script.mode(00755)
          @finish_script.source("sv-#{new_resource.finish_script_template_name}-finish.erb")
          @finish_script.cookbook(template_cookbook)
          if new_resource.options.respond_to?(:has_key?)
            @finish_script.variables(:options => new_resource.options)
          end
          @finish_script
        end

        def control_dir
          return @control_dir unless @control_dir.nil?
          @control_dir = Chef::Resource::Directory.new(::File.join(sv_dir_name, 'control'), run_context)
          @control_dir.owner(new_resource.owner)
          @control_dir.group(new_resource.group)
          @control_dir.mode(00755)
          @control_dir
        end

        def control_signal_files
          return @control_signal_files unless @control_signal_files.nil?
          @control_signal_files = new_resource.control.map do |signal|
            control_signal_file = Chef::Resource::Template.new(::File.join( sv_dir_name,
                                                                            'control',
                                                                            signal),
                                                                run_context)
            control_signal_file.owner(new_resource.owner)
            control_signal_file.group(new_resource.group)
            control_signal_file.mode(00755)
            control_signal_file.source("sv-#{new_resource.control_template_names[signal]}-#{signal}.erb")
            control_signal_file.cookbook(template_cookbook)
            if new_resource.options.respond_to?(:has_key?)
              control_signal_file.variables(:options => new_resource.options)
            end
            control_signal_file
          end
          @control_signal_files
        end

        def lsb_init
          return @lsb_init unless @lsb_init.nil?
          if node['platform'] == 'debian'
            @lsb_init = Chef::Resource::Template.new(::File.join( '/etc',
                                                                  'init.d',
                                                                  new_resource.service_name),
                                                      run_context)
            @lsb_init.owner('root')
            @lsb_init.group('root')
            @lsb_init.mode(00755)
            @lsb_init.cookbook('runit')
            @lsb_init.source('init.d.erb')
            @lsb_init.variables(:options => new_resource.options)
          else
            @lsb_init = Chef::Resource::Link.new(::File.join( '/etc',
                                                              'init.d',
                                                              new_resource.service_name),
                                                  run_context)
            @lsb_init.to(node['runit']['sv_bin'])
          end
          @lsb_init
        end

        def service_link
          return @service_link unless @service_link.nil?
          @service_link = Chef::Resource::Link.new(::File.join(service_dir_name), run_context)
          @service_link.to(sv_dir_name)
          @service_link
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

        def template_cookbook
          new_resource.cookbook.nil? ? new_resource.cookbook_name.to_s : new_resource.cookbook
        end

        def default_logger_content
          return <<-EOF
#!/bin/sh
exec svlogd -tt /var/log/#{new_resource.service_name}
EOF
        end
      end
    end
  end
end
