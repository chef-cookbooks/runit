#
# Cookbook:: runit
# Libraries:: helpers
#
# Author: Joshua Timberman <joshua@getchef.com>
# Copyright (c) 2014, Chef Software, Inc. <legal@getchef.com>
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

module RunitCookbook
  module Helpers
    def inside_docker?
      results = `cat /proc/1/cgroup`.strip.split("\n")
      results.any?{|val| /docker/ =~ val}
    end
    
    def runit_installed?
      return true if runit_rpm_installed? || (runit_executable? && runit_sv_works?)
    end

    def runit_executable?
      ::File.executable?(node['runit']['executable'])
    end

    def runit_sv_works?
      sv = shell_out("#{node['runit']['sv_bin']} --help")
      sv.exitstatus == 100 && sv.stderr =~ /usage: sv .* command service/
    end

    def runit_rpm_installed?
      shell_out('rpm -qa | grep -q "^runit"').exitstatus == 0
    end

    def runit_send_signal(signal, friendly_name = nil)
      friendly_name ||= signal
      converge_by("send #{friendly_name} to #{new_resource}") do
        shell_out!("#{new_resource.sv_bin} #{sv_args}#{signal} #{service_dir_name}")
        Chef::Log.info("#{new_resource} sent #{friendly_name}")
      end
    end

    def running?
      cmd = shell_out("#{new_resource.sv_bin} #{sv_args}status #{service_dir_name}")
      (cmd.stdout =~ /^run:/ && cmd.exitstatus == 0)
    end

    def log_running?
      cmd = shell_out("#{new_resource.sv_bin} #{sv_args}status #{service_dir_name}/log")
      (cmd.stdout =~ /^run:/ && cmd.exitstatus == 0)
    end

    def enabled?
      ::File.exists?(::File.join(service_dir_name, 'run'))
    end

    def log_service_name
      ::File.join(new_resource.service_name, 'log')
    end

    def sv_dir_name
      ::File.join(new_resource.sv_dir, new_resource.service_name)
    end

    def sv_args
      sv_args = ''
      sv_args += "-w '#{new_resource.sv_timeout}' " unless new_resource.sv_timeout.nil?
      sv_args += '-v ' if new_resource.sv_verbose
      sv_args
    end

    def service_dir_name
      ::File.join(new_resource.service_dir, new_resource.service_name)
    end

    def log_dir_name
      ::File.join(new_resource.service_dir, new_resource.service_name, log)
    end

    def template_cookbook
      new_resource.cookbook.nil? ? new_resource.cookbook_name.to_s : new_resource.cookbook
    end

    def default_logger_content
      "#!/bin/sh
exec svlogd -tt /var/log/#{new_resource.service_name}"
    end
    
  end
end
