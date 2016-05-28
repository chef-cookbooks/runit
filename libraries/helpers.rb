#
# Cookbook:: runit
# Libraries:: helpers
#
# Author: Joshua Timberman <joshua@chef.io>
# Author: Sean OMeara <sean@chef.io>
# Copyright 2008-2015, Chef Software, Inc. <legal@chef.io>
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
    # include Chef::Mixin::ShellOut if it is not already included in the calling class
    def self.included(klass)
      unless klass.ancestors.include?(Chef::Mixin::ShellOut)
        klass.class_eval { include Chef::Mixin::ShellOut }
      end
    end

    # Default settings for resource properties.
    def parsed_sv_bin
      return new_resource.sv_bin if new_resource.sv_bin
      '/usr/bin/sv'
    end

    def parsed_sv_dir
      return new_resource.sv_dir if new_resource.sv_dir
      '/etc/sv'
    end

    def parsed_service_dir
      return new_resource.service_dir if new_resource.service_dir
      '/etc/service'
    end

    def parsed_lsb_init_dir
      return new_resource.lsb_init_dir if new_resource.lsb_init_dir
      '/etc/init.d'
    end

    # misc helper functions
    def inside_docker?
      results = `cat /proc/1/cgroup`.strip.split("\n")
      results.any? { |val| /docker/ =~ val }
    end

    def down_file
      "#{sv_dir_name}/down"
    end

    def env_dir
      "#{sv_dir_name}/env"
    end

    def extra_env_files?
      files = []
      Dir.glob("#{sv_dir_name}/env/*").each do |f|
        files << File.basename(f)
      end
      return true if files.sort != new_resource.env.keys.sort
      false
    end

    def zap_extra_env_files
      Dir.glob("#{sv_dir_name}/env/*").each do |f|
        unless new_resource.env.key?(File.basename(f))
          File.unlink(f)
          Chef::Log.info("removing file #{f}")
        end
      end
    end

    # inspired on:
    # https://github.com/djberg96/sys-proctable/blob/master/lib/linux/sys/proctable.rb
    # Returns an array of hashes with keys: name and pid.
    def list_processes_with_pids()
      # there may be many processes of the same name, so use an array
      # of hashes
      processes = []
      Dir.foreach("/proc") do |file|
        next if file =~ /\D/ # Skip non-numeric directories

        # Get /proc/<pid>/cmdline information. Strip out embedded nulls.
        begin
          name = IO.read("/proc/#{file}/cmdline").tr("\000", ' ').strip
          processes.push({ name: name, pid: file})
        rescue
          next # Process terminated, on to the next process
        end
      end
      processes
    end

    # Looks for a line starting with "State:" in a specifed file
    # and returns the rest of the line.
    def read_state(status_file)
      File.open(status_file, 'r') do |file|
        lines = file.readlines
        lines.each do |line|
          if line.start_with?('State:')
            state = /State:\s+(.*)/.match(line)[1]
            return state
          end
        end
      end
    end

    # Returns true if a process is running, false otherwise.
    def is_process_running?(processes, process_name_pattern)
      matching_processes = []
      processes.each do |process|
        if process[:name] =~ /#{process_name_pattern}/
          matching_processes.push(process)
        end
      end
      if matching_processes.length > 1
        fail "#{process_name_pattern} matches more than 1 processes: "\
        "#{matching_processes}"
      elsif matching_processes.length == 0
        # "#{process_name_pattern} matches 0 processes"
        return false
      end
      status = read_state("/proc/#{matching_processes[0][:pid]}/status")
      if status.start_with?('R') || status.start_with?('S')
        return true
      else
        returns false
      end
    end

    # Checks if runsvdir process is running. runsvdir
    # starts and monitors services from #{parsed_service_dir}.
    # (http://smarden.org/runit/runsvdir.8.html).
    # True e.g. in a docker container which uses Phusion
    # baseimage-docker, but false when running `docker build`.
    def runsvdir_running?
      processes = list_processes_with_pids()
      # on ubuntu 14.04 inside docker the process is:
      #   /usr/bin/runsvdir -P /etc/service
      # on debian 7.8 in vm the process is:
      #   runsvdir -P /etc/service log: svlogd [-ttv] ...
      is_process_running?(processes, "runsvdir -P #{parsed_service_dir}")
    end

    # Checks if runsv process is running and monitors this service.
    def runsv_running?
      processes = list_processes_with_pids()
      is_process_running?(processes, "^runsv #{new_resource.service_name}$")
    end

    # Returns true if this service files are not yet created, in order to
    # avoid e.g. restart to happen before runsvdir actually initializes the
    # service directory (https://github.com/hw-cookbooks/runit/issues/60)
    def need_to_wait_for_service?
      if !(::FileTest.pipe?("#{service_dir_name}/supervise/ok"))
        Chef::Log.debug("#{service_dir_name}/supervise/ok does not exist")
        return true
      end

      if new_resource.log && !(::FileTest.pipe?("#{service_dir_name}/log/supervise/ok"))
        Chef::Log.debug("#{service_dir_name}/log/supervise/ok does not exist")
        return true
      end
      # Reason: when starting a service with sv, which controls and manages services
      # monitored by runsv(8), it fails with error:
      # "fail: <service_name>: runsv not running".
      if !(runsv_running?)
        Chef::Log.debug("runsv #{service_dir_name} is not running")
        return true
      end
    end

    def wait_for_service
      sleep 1 until !(need_to_wait_for_service?)
    end

    def runit_sv_works?
      sv = shell_out("#{sv_bin} --help")
      sv.exitstatus == 100 && sv.stderr =~ /usage: sv .* command service/
    end

    def runit_send_signal(signal, friendly_name = nil)
      friendly_name ||= signal
      converge_by("send #{friendly_name} to #{new_resource}") do
        shell_out!("#{sv_bin} #{sv_args}#{signal} #{service_dir_name}")
        Chef::Log.info("#{new_resource} sent #{friendly_name}")
      end
    end

    def running?
      cmd = shell_out("#{sv_bin} #{sv_args}status #{service_dir_name}")
      (cmd.stdout =~ /^run:/ && cmd.exitstatus == 0)
    end

    def log_running?
      cmd = shell_out("#{sv_bin} #{sv_args}status #{service_dir_name}/log")
      (cmd.stdout =~ /^run:/ && cmd.exitstatus == 0)
    end

    def enabled?
      ::File.exist?("#{service_dir_name}/run")
    end

    def log_service_name
      "#{new_resource.service_name}/log"
    end

    def sv_dir_name
      "#{parsed_sv_dir}/#{new_resource.service_name}"
    end

    def sv_args
      sv_args = ''
      sv_args += "-w '#{new_resource.sv_timeout}' " unless new_resource.sv_timeout.nil?
      sv_args += '-v ' if new_resource.sv_verbose
      sv_args
    end

    def sv_bin
      parsed_sv_bin
    end

    def service_dir_name
      "#{new_resource.service_dir}/#{new_resource.service_name}"
    end

    def log_dir_name
      "#{new_resource.service_dir}/#{new_resource.service_name}/log"
    end

    def template_cookbook
      new_resource.cookbook.nil? ? new_resource.cookbook_name.to_s : new_resource.cookbook
    end

    def default_logger_content
      <<-EOS
#!/bin/sh
exec svlogd -tt #{new_resource.log_dir}
      EOS
    end

    def disable_service
      shell_out("#{new_resource.sv_bin} #{sv_args}down #{service_dir_name}")
      FileUtils.rm(service_dir_name)

      # per the documentation, a service should be removed from supervision
      # within 5 seconds of removing the service dir symlink, so we'll sleep for 6.
      # otherwise, runit recreates the 'ok' named pipe too quickly
      sleep(6)
      # runit will recreate the supervise directory and
      # pipes when the service is reenabled
      FileUtils.rm("#{sv_dir_name}/supervise/ok")
    end

    def start_service
      shell_out!("#{new_resource.sv_bin} #{sv_args}start #{service_dir_name}")
    end

    def stop_service
      shell_out!("#{new_resource.sv_bin} #{sv_args}stop #{service_dir_name}")
    end

    def restart_service
      shell_out!("#{new_resource.sv_bin} #{sv_args}restart #{service_dir_name}")
    end

    def restart_log_service
      shell_out!("#{new_resource.sv_bin} #{sv_args}restart #{service_dir_name}/log")
    end

    def reload_service
      shell_out!("#{new_resource.sv_bin} #{sv_args}force-reload #{service_dir_name}")
    end

    def reload_log_service
      if log_running?
        shell_out!("#{new_resource.sv_bin} #{sv_args}force-reload #{service_dir_name}/log")
      end
    end
  end
end
