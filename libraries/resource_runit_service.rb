#
# Cookbook:: runit
# Provider:: service
#
# Copyright:: 2011-2016, Joshua Timberman
# Copyright:: 2011-2019, Chef Software, Inc.
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
    # Missing top-level class documentation comment
    class RunitService < Chef::Resource::Service
      resource_name :runit_service

      default_action :enable
      allowed_actions :nothing, :start, :stop, :enable, :disable, :restart, :reload, :status, :once, :hup, :cont, :term, :kill, :up, :down, :usr1, :usr2, :create

      # For legacy reasons we allow setting these via attribute
      property :sv_bin, String, default: lazy { node['runit']['sv_bin'] || '/usr/bin/sv' }
      property :sv_dir, [String, FalseClass], default: lazy { node['runit']['sv_dir'] || '/etc/sv' }
      property :service_dir, String, default: lazy { node['runit']['service_dir'] || '/etc/service' }
      property :lsb_init_dir, String, default: lazy { node['runit']['lsb_init_dir'] || '/etc/init.d' }

      property :control, Array, default: []
      property :options, Hash, default: {}
      property :env, Hash, default: {}
      property :log, [TrueClass, FalseClass], default: true
      property :cookbook, String
      property :check, [TrueClass, FalseClass], default: false
      property :start_down, [TrueClass, FalseClass], default: false
      property :delete_downfile, [TrueClass, FalseClass], default: false
      property :finish, [TrueClass, FalseClass], default: false
      property :supervisor_owner, String, regex: [Chef::Config[:user_valid_regex]]
      property :supervisor_group, String, regex: [Chef::Config[:group_valid_regex]]
      property :owner, String, regex: [Chef::Config[:user_valid_regex]]
      property :group, String, regex: [Chef::Config[:group_valid_regex]]
      property :enabled, [TrueClass, FalseClass], default: false
      property :running, [TrueClass, FalseClass], default: false
      property :default_logger, [TrueClass, FalseClass], default: false
      property :restart_on_update, [TrueClass, FalseClass], default: true
      property :run_template_name, String, default: lazy { service_name }
      property :log_template_name, String, default: lazy { service_name }
      property :check_script_template_name, String, default: lazy { service_name }
      property :finish_script_template_name, String, default: lazy { service_name }
      property :control_template_names, Hash, default: lazy { set_control_template_names }
      property :status_command, String, default: lazy { "#{sv_bin} status #{service_dir}" }
      property :sv_templates, [TrueClass, FalseClass], default: true
      property :sv_timeout, Integer
      property :sv_verbose, [TrueClass, FalseClass], default: false
      property :log_dir, String, default: lazy { ::File.join('/var/log/', service_name) }
      property :log_flags, String, default: '-tt'
      property :log_size, Integer
      property :log_num, Integer
      property :log_min, Integer
      property :log_timeout, Integer
      property :log_processor, String
      property :log_socket, [String, Hash]
      property :log_prefix, String
      property :log_config_append, String

      alias template_name run_template_name

      def set_control_template_names
        control.each do |signal|
          control_template_names[signal] ||= service_name
        end
        control_template_names
      end

      def initialize(name, run_context = nil)
        super

        #
        # Backward Compat Hack
        #
        # This ensures a 'service' resource exists for all 'runit_service' resources.
        # This should allow all recipes using the previous 'runit_service' definition to
        # continue operating.
        #
        unless run_context.nil?
          service_dir_name = ::File.join(service_dir, name)
          @service_mirror = Chef::Resource::Service.new(name, run_context)
          @service_mirror.provider(Chef::Provider::Service::Simple)
          @service_mirror.supports(supports)
          @service_mirror.start_command("#{sv_bin} start #{service_dir_name}")
          @service_mirror.stop_command("#{sv_bin} stop #{service_dir_name}")
          @service_mirror.restart_command("#{sv_bin} restart #{service_dir_name}")
          @service_mirror.status_command("#{sv_bin} status #{service_dir_name}")
          @service_mirror.action(:nothing)
          run_context.resource_collection.insert(@service_mirror)
        end
      end

      # def options(arg = nil)
      #   default_opts = @env.empty? ? @options : @options.merge(env_dir: ::File.join(@sv_dir, @service_name, 'env'))
      #
      #   merged_opts = arg.respond_to?(:merge) ? default_opts.merge(arg) : default_opts
      #
      #   set_or_return(
      #     :options,
      #     merged_opts,
      #     kind_of: [Hash],
      #     default: default_opts
      #   )
      # end
    end
  end
end
