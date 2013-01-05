#
# Author:: Joshua Timberman <joshua@opscode.com>
# Copyright:: Copyright (c) 2012, Opscode, Inc. <legal@opscode.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/platform'
require 'chef/run_context'
require 'chef/cookbook/metadata'
require 'chef/event_dispatch/dispatcher'
require 'chef/runner'

$:.unshift(File.join(File.dirname(__FILE__), "..", "..", "libraries"))
require 'provider_runit_service'
require 'resource_runit_service'

describe "Chef::Resource::RunitService" do

  before(:each) do
    @resource = Chef::Resource::RunitService.new('getty.service')
  end

  it 'should return a Chef::Resource::RunitService' do
    @resource.should be_a_kind_of(Chef::Resource::RunitService)
  end

  it 'should set the resource_name to :runit_service' do
    @resource.resource_name.should == :runit_service
  end

  it 'should set the provider to Chef::Provider::Service::Runit' do
    @resource.provider.should == Chef::Provider::Service::Runit
  end

  it 'sets the service_name to the name attribute' do
    @resource.service_name.should == 'getty.service'
  end

  it 'has an sv_dir parameter set to /etc/sv by default' do
    @resource.sv_dir.should == '/etc/sv'
  end

  it 'has an sv_dir parameter that can be set' do
    @resource.sv_dir('/var/lib/sv')
    @resource.sv_dir.should == '/var/lib/sv'
  end

  it 'allows sv_dir parameter to be set false (so users can use an existing sv dir)' do
    @resource.sv_dir(false)
    @resource.sv_dir.should be_false
  end

  it 'has a service_dir parameter set to /etc/service by default' do
    @resource.service_dir.should == '/etc/service'
  end

  it 'has a service_dir parameter that can be set' do
    @resource.service_dir('/var/service')
    @resource.service_dir.should == '/var/service'
  end

  it 'has a control parameter that can be set as an array of service control characters' do
    @resource.control(['s', 'u'])
    @resource.control.should == ['s', 'u']
  end

  it 'has an options parameter that can be set as a hash of arbitrary options' do
    @resource.options({:binary => '/usr/bin/noodles'})
    @resource.options.should have_key(:binary)
    @resource.options[:binary].should == '/usr/bin/noodles'
  end

  it 'has an env parameter that can be set as a hash of environment variables' do
    @resource.env({'PATH' => '$PATH:/usr/local/bin'})
    @resource.env.should have_key('PATH')
    @resource.env['PATH'].should include('/usr/local/bin')
  end

  it 'adds :env_dir to options if env is set' do
    @resource.env({'PATH' => '/bin'})
    @resource.options.should have_key(:env_dir)
    @resource.options[:env_dir].should == ::File.join(@resource.sv_dir, @resource.service_name, 'env')
  end

  it 'has a log parameter to control whether a log service is setup' do
    @resource.log.should be_true
  end

  it 'has a log parameter that can be set to false' do
    @resource.log(false)
    @resource.log.should be_false
  end

  it 'raises an exception if the log parameter is set to nil' do
    @resource.log(nil)
    @resource.log.should raise_exception
  end

  it 'has a cookbook parameter that can be set' do
    @resource.cookbook('noodles')
    @resource.cookbook.should == 'noodles'
  end

  it 'has a finish parameter that is false by default' do
    @resource.finish.should be_false
  end

  it 'hash a finish parameter that controls whether a finish script is created' do
    @resource.finish(true)
    @resource.finish.should be_true
  end

  it 'has an owner parameter that can be set' do
    @resource.owner('monkey')
    @resource.owner.should == 'monkey'
  end

  it 'has a group parameter that can be set' do
    @resource.group('primates')
    @resource.group.should == 'primates'
  end

  it 'has an enabled parameter to determine if the current resource is enabled' do
    @resource.enabled.should be_false
  end

  it 'has a running parameter to determine if the current resource is running' do
    @resource.running.should be_false
  end

  it 'has a default_logger parameter that is false by default' do
    @resource.default_logger.should be_false
  end

  it 'has a default_logger parameter that controls whether a default log template should be created' do
    @resource.default_logger(true)
    @resource.default_logger.should == true
  end

  it 'sets the log_template_name to the service_name by default' do
    @resource.log_template_name.should == @resource.service_name
  end

  it 'has a log_template_name parameter to allow a custom template name for the log run script' do
    @resource.log_template_name('write_noodles')
    @resource.log_template_name.should == 'write_noodles'
  end

  it 'sets the control_template_names for each control character to the service_name by default' do
    @resource.control(['s', 'u'])
    @resource.control_template_names.should have_key('s')
    @resource.control_template_names.should have_key('u')
    @resource.control_template_names['s'].should == @resource.service_name
    @resource.control_template_names['u'].should == @resource.service_name
  end

  it 'has a control_template_names parameter to allow custom template names for the control scripts' do
    @resource.control_template_names({
        's' => 'banana_start',
        'u' => 'noodle_up'
      })
    @resource.control_template_names.should have_key('s')
    @resource.control_template_names.should have_key('u')
    @resource.control_template_names['s'].should == 'banana_start'
    @resource.control_template_names['u'].should == 'noodle_up'
  end

  it 'sets the finish_script_template_name to the service_name by default' do
    @resource.finish_script_template_name.should == @resource.service_name
  end

  it 'has a finish_script_template_name parameter to allow a custom template name for the finish script' do
    @resource.finish_script_template_name('eat_bananas')
    @resource.finish_script_template_name.should == 'eat_bananas'
  end

end

describe "Chef::Provider::Service::Runit" do
  before(:each) do
    md = Chef::Cookbook::Metadata.new
    md.from_file(File.join(File.dirname(__FILE__), '..', '..', 'metadata.rb'))
    @node = Chef::Node.new
    @node.automatic['platform'] = 'ubuntu'
    @node.automatic['platform_version'] = '12.04'
    @node.set['runit']['sv_bin'] = '/usr/bin/sv'
    @events = Chef::EventDispatch::Dispatcher.new
    @run_context = Chef::RunContext.new(@node, Chef::CookbookCollection.new({}), @events)
    @new_resource = Chef::Resource::RunitService.new('getty.service')
    @provider = Chef::Provider::Service::Runit.new(@new_resource, @run_context)
    @runner = Chef::Runner.new(@run_context)
  end

  describe "load_current_resource" do
    before(:each) do
      @current_resource = Chef::Resource::RunitService.new('getty.service')
      @service_dir_name = "#{@current_resource.service_dir}/#{@current_resource.service_name}"
      Chef::Resource::RunitService.stub!(:new).and_return(@current_resource)

      @provider.stub!(:running?).and_return(false)
      @provider.stub!(:enabled?).and_return(false)
    end

    it 'should create a current resource with the name of the new resource' do
      Chef::Resource::RunitService.should_receive(:new).and_return(@current_resource)
      @provider.load_current_resource
    end

    it 'should set the current resource service name to the new resource service name' do
      @current_resource.should_receive(:service_name).with(@new_resource.service_name)
      @provider.load_current_resource
    end

    it 'should check if the service is running' do
      @provider.should_receive(:running?)
      @provider.load_current_resource
    end

    it 'should set running to true if the service is running' do
      @provider.stub!(:running?).and_return(true)
      @current_resource.should_receive(:running).with(true)
      @provider.load_current_resource
    end

    it 'should set running to false if the service is not running' do
      @provider.stub!(:running?).and_return(false)
      @current_resource.should_receive(:running).with(false)
      @provider.load_current_resource
    end

    it 'should set enabled to false if the run script is not present' do
      @provider.stub!(:enabled?).and_return(false)
      @current_resource.should_receive(:enabled).with(false)
      @provider.load_current_resource
    end

    it 'should set enabled to true if the run script is present in the service_dir' do
      @provider.stub!(:enabled?).and_return(true)
      @current_resource.should_receive(:enabled).with(true)
      @provider.load_current_resource
    end

    describe "actions that start the service" do
      %w{start up once cont}.each do |action|
        it "sends the #{action} command to the sv binary" do
          @provider.should_receive(:shell_out!).with("#{@node['runit']['sv_bin']} #{action} #{@service_dir_name}")
          @provider.run_action(action.to_sym)
        end
      end
    end

    describe 'action_reload' do
      it "sends the 'force-reload' command to the sv binary" do
        @current_resource.stub!(:running).and_return(true)
        @provider.should_receive(:shell_out!).with("#{@node['runit']['sv_bin']} force-reload #{@service_dir_name}")
        @provider.run_action(:reload)
      end
    end

    describe 'action_usr1' do
      it 'sends the usr1 signal to the sv binary' do
        @current_resource.stub!(:running).and_return(true)
        @provider.should_receive(:shell_out!).with("#{@node['runit']['sv_bin']} 1 #{@service_dir_name}")
        @provider.run_action(:usr1)
      end
    end

    describe 'action_usr2' do
      it 'sends the usr2 signal to the sv binary' do
        @current_resource.stub!(:running).and_return(true)
        @provider.should_receive(:shell_out!).with("#{@node['runit']['sv_bin']} 2 #{@service_dir_name}")
        @provider.run_action(:usr2)
      end
    end

    describe 'actions that manage a running service' do
      %w{stop down restart hup int term kill}.each do |action|
        it "sends the '#{action}' command to the sv binary" do
          @current_resource.stub!(:running).and_return(true)
          @provider.should_receive(:shell_out!).with("#{@node['runit']['sv_bin']} #{action} #{@service_dir_name}")
          @provider.run_action(action.to_sym)
        end
      end
    end

    describe 'action_disable' do
      it 'disables the service by running the down command and removing the symlink' do
        @current_resource.stub!(:enabled).and_return(true)
        @provider.should_receive(:shell_out!).with("#{@node['runit']['sv_bin']} down #{@service_dir_name}")
        FileUtils.should_receive(:rm).with(@service_dir_name)
        @provider.run_action(:disable)
      end
    end

    describe "action_enable" do
      before(:each) do
        @current_resource.stub!(:enabled).and_return(true)
        @sv_dir_name = ::File.join(@new_resource.sv_dir, @new_resource.service_name)
        @service_dir_name = ::File.join(@new_resource.service_dir, @new_resource.service_name)
      end

      it 'creates the sv_dir directory' do
        @provider.sv_dir.path.should == ::File.join(@sv_dir_name)
        @provider.sv_dir.recursive.should be_true
        @provider.sv_dir.owner.should == @new_resource.owner
        @provider.sv_dir.group.should == @new_resource.group
        @provider.sv_dir.mode.should == 00755
      end

      it 'creates the run script template' do
        @provider.run_script.path.should == ::File.join(@sv_dir_name, 'run')
        @provider.run_script.owner.should == @new_resource.owner
        @provider.run_script.group.should == @new_resource.group
        @provider.run_script.mode.should == 00755
        @provider.run_script.source.should == "sv-#{@new_resource.service_name}-run.erb"
        @provider.run_script.cookbook.should be_nil
      end

      it 'sets up the supervised log directory and run script' do
        @provider.log_dir.path.should == ::File.join(@sv_dir_name, 'log')
        @provider.log_dir.recursive.should be_true
        @provider.log_dir.owner.should == @new_resource.owner
        @provider.log_dir.group.should == @new_resource.group
        @provider.log_dir.mode.should == 00755
        @provider.log_run_script.path.should == ::File.join(@sv_dir_name, 'log', 'run')
        @provider.log_run_script.owner.should == @new_resource.owner
        @provider.log_run_script.group.should == @new_resource.group
        @provider.log_run_script.mode.should == 00755
        @provider.log_run_script.source.should == "sv-#{@new_resource.log_template_name}-log-run.erb"
        @provider.log_run_script.cookbook.should be_nil
      end

      it 'creates log/run with default content if default_logger parameter is true' do
        script_content = "exec svlogd -tt /var/log/#{@new_resource.service_name}"
        @new_resource.default_logger(true)
        @provider.log_run_script.path.should == ::File.join(@sv_dir_name, 'log', 'run')
        @provider.log_run_script.owner.should == @new_resource.owner
        @provider.log_run_script.group.should == @new_resource.group
        @provider.log_run_script.mode.should == 00755
        @provider.log_run_script.content.should include(script_content)
      end

      it 'creates env directory and files' do
        @provider.env_dir.path.should == ::File.join(@sv_dir_name, 'env')
        @provider.env_dir.owner.should == @new_resource.owner
        @provider.env_dir.group.should == @new_resource.group
        @provider.env_dir.mode.should == 00755
        @new_resource.env({'PATH' => '$PATH:/usr/local/bin'})
        @provider.env_files[0].path.should == ::File.join(@sv_dir_name, 'env', 'PATH')
        @provider.env_files[0].owner.should == @new_resource.owner
        @provider.env_files[0].group.should == @new_resource.group
        @provider.env_files[0].content.should == '$PATH:/usr/local/bin'
      end

      it 'creates a finish script as a template if finish_script parameter is true' do
        @provider.finish_script.path.should == ::File.join(@sv_dir_name, 'finish')
        @provider.finish_script.owner.should == @new_resource.owner
        @provider.finish_script.group.should == @new_resource.group
        @provider.finish_script.mode.should == 00755
        @provider.finish_script.source.should == "sv-#{@new_resource.finish_script_template_name}-finish.erb"
        @provider.finish_script.cookbook.should be_nil
      end

      it 'creates control directory and signal files' do
        @provider.control_dir.path.should == ::File.join(@sv_dir_name, 'control')
        @provider.control_dir.owner.should == @new_resource.owner
        @provider.control_dir.group.should == @new_resource.group
        @provider.control_dir.mode.should == 00755
        @new_resource.control(['s'])
        @provider.control_signal_files[0].path.should == ::File.join(@sv_dir_name, 'control', 's')
        @provider.control_signal_files[0].owner.should == @new_resource.owner
        @provider.control_signal_files[0].group.should == @new_resource.group
        @provider.control_signal_files[0].source.should == "sv-#{@new_resource.control_template_names['s']}-s.erb"
        @provider.control_signal_files[0].cookbook.should be_nil
      end

      it 'creates a symlink for LSB script compliance unless the platform is debian' do
        @node.automatic['platform'] = 'not_debian'
        @provider.lsb_init.path.should == ::File.join('/etc', 'init.d', @new_resource.service_name)
        @provider.lsb_init.to.should == ::File.join(@node['runit']['sv_bin'])
      end

      it 'creates an init script as a template for LSB compliance if the platform is debian' do
        @node.automatic['platform'] = 'debian'
        @provider.lsb_init.path.should == ::File.join('/etc', 'init.d', @new_resource.service_name)
        @provider.lsb_init.owner.should == 'root'
        @provider.lsb_init.group.should == 'root'
        @provider.lsb_init.mode.should == 00755
        @provider.lsb_init.cookbook.should == 'runit'
        @provider.lsb_init.source.should == 'init.d.erb'
        @provider.lsb_init.variables.should have_key(:options)
        @provider.lsb_init.variables[:options].should == @new_resource.options
      end

      it 'creates a symlink from the sv dir to the service' do
        @provider.service_link.path.should == ::File.join(@service_dir_name)
        @provider.service_link.to.should == ::File.join(@sv_dir_name)
      end

      it 'creates the sv dir and service dir symlink using resource creation methods' do
        pending
      end

    end
  end
end
