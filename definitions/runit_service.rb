#
# Cookbook Name:: runit
# Definition:: runit_service
#
# Copyright 2008-2009, Opscode, Inc.
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

define :runit_service, :directory => nil, :only_if => false, :finish_script => false, :control => [], :run_restart => true, :active_directory => nil, :owner => "root", :group => "root", :template_name => nil, :log_template_name => nil, :control_template_names => {}, :finish_script_template_name => nil, :start_command => "start", :stop_command => "stop", :restart_command => "restart", :status_command => "status", :options => Hash.new, :env => Hash.new do
  include_recipe "runit"

  params[:directory] ||= node[:runit][:sv_dir]
  params[:active_directory] ||= node[:runit][:service_dir]
  params[:template_name] ||= params[:name]
  params[:log_template_name] ||= params[:template_name]
  params[:control].each do |signal|
    params[:control_template_names][signal] ||= params[:template_name]
  end
  params[:finish_script_template_name] ||= params[:template_name]

  sv_dir_name = "#{params[:directory]}/#{params[:name]}"
  service_dir_name = "#{params[:active_directory]}/#{params[:name]}"
  params[:options].merge!(:env_dir => "#{sv_dir_name}/env") unless params[:env].empty?

  directory sv_dir_name do
    owner params[:owner]
    group params[:group]
    mode 0755
    action :create
  end

  directory "#{sv_dir_name}/log" do
    owner params[:owner]
    group params[:group]
    mode 0755
    action :create
  end

  directory "#{sv_dir_name}/supervise" do
    owner params[:owner]
    group params[:group]
    mode 0755
    action :create
  end

  directory "#{sv_dir_name}/log/main" do
    owner params[:owner]
    group params[:group]
    mode 0755
    action :create
  end

  # Create the down-file so the service doesn't automatically start 
  # before we can set permission on the named pipes
  file "#{sv_dir_name}/down" do
    owner params[:owner]
    group params[:group]
    mode 0755
  end  

  template "#{sv_dir_name}/run" do
    owner params[:owner]
    group params[:group]
    mode 0755
    source "sv-#{params[:template_name]}-run.erb"
    cookbook params[:cookbook] if params[:cookbook]
    if params[:options].respond_to?(:has_key?)
      variables :options => params[:options]
    end
  end

  template "#{sv_dir_name}/log/run" do
    owner params[:owner]
    group params[:group]
    mode 0755
    source "sv-#{params[:log_template_name]}-log-run.erb"
    cookbook params[:cookbook] if params[:cookbook]
    if params[:options].respond_to?(:has_key?)
      variables :options => params[:options]
    end
  end

  unless params[:env].empty?
    directory "#{sv_dir_name}/env" do
      mode 0755
      action :create
    end

    params[:env].each do |var, value|
      file "#{sv_dir_name}/env/#{var}" do
        content value
      end
    end
  end

  if params[:finish_script]
    template "#{sv_dir_name}/finish" do
      owner params[:owner]
      group params[:group]
      mode 0755
      source "sv-#{params[:finish_script_template_name]}-finish.erb"
      cookbook params[:cookbook] if params[:cookbook]
      if params[:options].respond_to?(:has_key?)
        variables :options => params[:options]
      end
    end
  end

  unless params[:control].empty?
    directory "#{sv_dir_name}/control" do
      owner params[:owner]
      group params[:group]
      mode 0755
      action :create
    end

    params[:control].each do |signal|
      template "#{sv_dir_name}/control/#{signal}" do
        owner params[:owner]
        group params[:group]
        mode 0755
        source "sv-#{params[:control_template_names][signal]}-control-#{signal}.erb"
        cookbook params[:cookbook] if params[:cookbook]
        if params[:options].respond_to?(:has_key?)
          variables :options => params[:options]
        end
      end
    end
  end

  if params[:active_directory] == node[:runit][:service_dir]
    link "/etc/init.d/#{params[:name]}" do
      owner params[:owner]
      group params[:group]
      to node[:runit][:sv_bin]
    end
  end

  unless node[:platform] == "gentoo"
    link service_dir_name do
      owner params[:owner]
      group params[:group]
      to sv_dir_name
    end
  end

  ruby_block "supervise_#{params[:name]}_sleep" do
    block do
      Chef::Log.debug("Waiting until named pipe #{sv_dir_name}/supervise/ok exists.")
      (1..10).each {|i| sleep 1 unless ::FileTest.pipe?("#{sv_dir_name}/supervise/ok") }
    end
    not_if { FileTest.pipe?("#{sv_dir_name}/supervise/ok") }
    notifies :create, "ruby_block[supervise_#{params[:name]}_pipes_set_ownership]", :immediately
  end

  ruby_block "supervise_#{params[:name]}_pipes_set_ownership" do
    block do
      Chef::Log.debug("Setting ownership on named pipes in '#{sv_dir_name}/supervise/'...")
      ::Dir.glob("#{sv_dir_name}/supervise/*").each do | supervise_file | 
        file_resource = Chef::Resource::File.new(supervise_file)
        file_resource.owner(params[:owner])
        file_resource.group(params[:group])

        access_control = Chef::FileAccessControl.new(file_resource, file_resource.path)
        Chef::Log.debug("Setting ownership for named pipe '#{supervise_file}' to #{file_resource.owner}:#{file_resource.group}...")
        access_control.set_all
      end
    end
    notifies :delete, "file[#{sv_dir_name}/down]", :immediately # Remove down file when we're all set for permissions
  end

  service params[:name] do
    control_cmd = node[:runit][:sv_bin]
    if params[:owner]
      control_cmd = "#{node[:runit][:chpst_bin]} -u #{params[:owner]} #{control_cmd}"
    end
    provider Chef::Provider::Service::Init
    supports :restart => true, :status => true
    start_command "#{control_cmd} #{params[:start_command]} #{service_dir_name}"
    stop_command "#{control_cmd} #{params[:stop_command]} #{service_dir_name}"
    restart_command "#{control_cmd} #{params[:restart_command]} #{service_dir_name}"
    status_command "#{control_cmd} #{params[:status_command]} #{service_dir_name}"
    if params[:run_restart]
      subscribes :restart, resources(:template => "#{sv_dir_name}/run"), :delayed
    end
    action :nothing
  end

end
