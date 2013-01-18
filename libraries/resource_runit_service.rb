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

require 'chef/resource'
require 'chef/resource/service'

class Chef
  class Resource
    class RunitService < Chef::Resource::Service

      def initialize(name, run_context=nil)
        super
        @resource_name = :runit_service
        @provider = Chef::Provider::Service::Runit
        @supports = { :restart => true, :reload => true, :status => true }
        @action = :enable
        @allowed_actions = [:start, :stop, :enable, :disable, :restart, :reload, :status, :once, :hup, :cont, :term, :kill, :up, :down, :usr1, :usr2]
        @sv_dir = '/etc/sv'
        @service_dir = '/etc/service'
        @control = []
        @options = {}
        @env = {}
        @log = true
        @cookbook = nil
        @finish = false
        @enabled = false
        @running = false
        @default_logger = false
        @log_template_name = @service_name
        @finish_script_template_name = @service_name
        @control_template_names = {}
        @status_command = "/usr/bin/sv status #{@service_dir}"
      end

      def sv_dir(arg=nil)
        set_or_return(:sv_dir, arg, :kind_of => [String, FalseClass])
      end

      def service_dir(arg=nil)
        set_or_return(:service_dir, arg, :kind_of => [String])
      end

      def control(arg=nil)
        set_or_return(:control, arg, :kind_of => [Array])
      end

      def options(arg=nil)
        if @env.empty?
          opts = @options
        else
          opts = @options.merge!(:env_dir => ::File.join(@sv_dir, @service_name, 'env'))
        end
        set_or_return(
          :options,
          arg,
          :kind_of => [Hash],
          :default => opts
        )
      end

      def env(arg=nil)
        set_or_return(:env, arg, :kind_of => [Hash])
      end

      def log(arg=nil)
        set_or_return(:log, arg, :kind_of => [TrueClass, FalseClass])
      end

      def cookbook(arg=nil)
        set_or_return(:cookbook, arg, :kind_of => [String])
      end

      def finish(arg=nil)
        set_or_return(:finish, arg, :kind_of => [TrueClass, FalseClass])
      end

      def owner(arg=nil)
        set_or_return(:owner, arg, :regex => [Chef::Config[:user_valid_regex]])
      end

      def group(arg=nil)
        set_or_return(:group, arg, :regex => [Chef::Config[:group_valid_regex]])
      end

      def enabled(arg=nil)
        set_or_return(:enabled, arg, :kind_of => [TrueClass, FalseClass])
      end

      def running(arg=nil)
        set_or_return(:enabled, arg, :kind_of => [TrueClass, FalseClass])
      end

      def default_logger(arg=nil)
        set_or_return(:default_logger, arg, :kind_of => [TrueClass, FalseClass])
      end

      def log_template_name(arg=nil)
        set_or_return(:log_template_name, arg, :kind_of => [String])
      end

      def finish_script_template_name(arg=nil)
        set_or_return(:finish_script_template_name, arg, :kind_of => [String])
      end

      def control_template_names(arg=nil)
        set_or_return(
          :control_template_names,
          arg,
          :kind_of => [Hash],
          :default => set_control_template_names
        )
      end

      def set_control_template_names
        @control.each do |signal|
          @control_template_names[signal] ||= @service_name
        end
        @control_template_names
      end

    end
  end
end
