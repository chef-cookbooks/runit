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

  it 'has a sv_templates parameter to control whether the sv_dir templates are created' do
    @resource.sv_templates(false)
    @resource.sv_templates.should be_false
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

    it 'should set running to false if the service is not running' do
      @provider.load_current_resource
      @current_resource.running.should be_false
    end

    it 'should set running to true if the service is running' do
      @provider.stub!(:running?).and_return(true)
      @provider.stub!(:enabled?).and_return(true)
      @provider.load_current_resource
      @current_resource.running.should be_true
    end

    it 'should set enabled to false if the run script is not present' do
      @provider.load_current_resource
      @current_resource.enabled.should be_false
    end

    it 'should set enabled to true if the run script is present in the service_dir' do
      @provider.stub!(:running?).and_return(true)
      @provider.stub!(:enabled?).and_return(true)
      @provider.load_current_resource
      @current_resource.enabled.should be_true
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
        @provider.should_receive(:shell_out).with("#{@node['runit']['sv_bin']} down #{@service_dir_name}")
        FileUtils.should_receive(:rm).with(@service_dir_name)
        @provider.run_action(:disable)
      end
    end

    describe "action_enable" do
      before(:each) do
        @current_resource.stub!(:enabled).and_return(true)
        @sv_dir_name = ::File.join(@new_resource.sv_dir, @new_resource.service_name)
        @service_dir_name = ::File.join(@new_resource.service_dir, @new_resource.service_name)
        FileTest.stub!(:pipe?).with("#{@service_dir_name}/supervise/ok").and_return(true)
      end

      it 'creates the sv_dir directory' do
        @provider.send(:sv_dir).path.should eq(::File.join(@sv_dir_name))
        @provider.send(:sv_dir).recursive.should be_true
        @provider.send(:sv_dir).owner.should eq(@new_resource.owner)
        @provider.send(:sv_dir).group.should eq(@new_resource.group)
        @provider.send(:sv_dir).mode.should == 00755
      end

      it 'creates the run script template' do
        @provider.send(:run_script).path.should eq(::File.join(@sv_dir_name, 'run'))
        @provider.send(:run_script).owner.should eq(@new_resource.owner)
        @provider.send(:run_script).group.should eq(@new_resource.group)
        @provider.send(:run_script).mode.should eq(00755)
        @provider.send(:run_script).source.should eq("sv-#{@new_resource.service_name}-run.erb")
        @provider.send(:run_script).cookbook.should be_empty
      end

      it 'sets up the supervised log directory and run script' do
        @provider.send(:log_dir).path.should eq(::File.join(@sv_dir_name, 'log'))
        @provider.send(:log_dir).recursive.should be_true
        @provider.send(:log_dir).owner.should eq(@new_resource.owner)
        @provider.send(:log_dir).group.should eq(@new_resource.group)
        @provider.send(:log_dir).mode.should eq(00755)
        @provider.send(:log_main_dir).path.should eq(::File.join(@sv_dir_name, 'log', 'main'))
        @provider.send(:log_main_dir).recursive.should be_true
        @provider.send(:log_main_dir).owner.should eq(@new_resource.owner)
        @provider.send(:log_main_dir).group.should eq(@new_resource.group)
        @provider.send(:log_main_dir).mode.should eq(00755)
        @provider.send(:log_run_script).path.should eq(::File.join(@sv_dir_name, 'log', 'run'))
        @provider.send(:log_run_script).owner.should eq(@new_resource.owner)
        @provider.send(:log_run_script).group.should eq(@new_resource.group)
        @provider.send(:log_run_script).mode.should eq(00755)
        @provider.send(:log_run_script).source.should eq("sv-#{@new_resource.log_template_name}-log-run.erb")
        @provider.send(:log_run_script).cookbook.should be_empty
      end

      it 'creates log/run with default content if default_logger parameter is true' do
        script_content = "exec svlogd -tt /var/log/#{@new_resource.service_name}"
        @new_resource.default_logger(true)
        @provider.send(:log_run_script).path.should eq(::File.join(@sv_dir_name, 'log', 'run'))
        @provider.send(:log_run_script).owner.should eq(@new_resource.owner)
        @provider.send(:log_run_script).group.should eq(@new_resource.group)
        @provider.send(:log_run_script).mode.should eq(00755)
        @provider.send(:log_run_script).content.should include(script_content)
        @provider.send(:default_log_dir).path.should eq(::File.join('/var', 'log', @new_resource.service_name))
        @provider.send(:default_log_dir).recursive.should be_true
        @provider.send(:default_log_dir).owner.should eq(@new_resource.owner)
        @provider.send(:default_log_dir).group.should eq(@new_resource.group)
        @provider.send(:default_log_dir).mode.should eq(00755)
      end

      it 'creates env directory and files' do
        @provider.send(:env_dir).path.should eq(::File.join(@sv_dir_name, 'env'))
        @provider.send(:env_dir).owner.should eq(@new_resource.owner)
        @provider.send(:env_dir).group.should eq(@new_resource.group)
        @provider.send(:env_dir).mode.should eq(00755)
        @new_resource.env({'PATH' => '$PATH:/usr/local/bin'})
        @provider.send(:env_files)[0].path.should eq(::File.join(@sv_dir_name, 'env', 'PATH'))
        @provider.send(:env_files)[0].owner.should eq(@new_resource.owner)
        @provider.send(:env_files)[0].group.should eq(@new_resource.group)
        @provider.send(:env_files)[0].content.should eq('$PATH:/usr/local/bin')
      end

      it 'creates a finish script as a template if finish_script parameter is true' do
        @provider.send(:finish_script).path.should eq(::File.join(@sv_dir_name, 'finish'))
        @provider.send(:finish_script).owner.should eq(@new_resource.owner)
        @provider.send(:finish_script).group.should eq(@new_resource.group)
        @provider.send(:finish_script).mode.should eq(00755)
        @provider.send(:finish_script).source.should eq("sv-#{@new_resource.finish_script_template_name}-finish.erb")
        @provider.send(:finish_script).cookbook.should be_empty
      end

      it 'creates control directory and signal files' do
        @provider.send(:control_dir).path.should eq(::File.join(@sv_dir_name, 'control'))
        @provider.send(:control_dir).owner.should eq(@new_resource.owner)
        @provider.send(:control_dir).group.should eq(@new_resource.group)
        @provider.send(:control_dir).mode.should eq(00755)
        @new_resource.control(['s'])
        @provider.send(:control_signal_files)[0].path.should eq(::File.join(@sv_dir_name, 'control', 's'))
        @provider.send(:control_signal_files)[0].owner.should eq(@new_resource.owner)
        @provider.send(:control_signal_files)[0].group.should eq(@new_resource.group)
        @provider.send(:control_signal_files)[0].mode.should eq(00755)
        @provider.send(:control_signal_files)[0].source.should eq("sv-#{@new_resource.control_template_names['s']}-s.erb")
        @provider.send(:control_signal_files)[0].cookbook.should be_empty
      end

      it 'creates a symlink for LSB script compliance unless the platform is debian' do
        @node.automatic['platform'] = 'not_debian'
        @provider.send(:lsb_init).path.should eq(::File.join('/etc', 'init.d', @new_resource.service_name))
        @provider.send(:lsb_init).to.should eq(::File.join(@node['runit']['sv_bin']))
      end

      it 'creates an init script as a template for LSB compliance if the platform is debian' do
        @node.automatic['platform'] = 'debian'
        @provider.send(:lsb_init).path.should eq(::File.join('/etc', 'init.d', @new_resource.service_name))
        @provider.send(:lsb_init).owner.should eq('root')
        @provider.send(:lsb_init).group.should eq('root')
        @provider.send(:lsb_init).mode.should eq(00755)
        @provider.send(:lsb_init).cookbook.should eq('runit')
        @provider.send(:lsb_init).source.should eq('init.d.erb')
        @provider.send(:lsb_init).variables.should have_key(:options)
        @provider.send(:lsb_init).variables[:options].should eq(@new_resource.options)
      end

      it 'does not create anything in the sv_dir if it is nil or false' do
        @current_resource.stub!(:enabled).and_return(false)
        @new_resource.stub!(:sv_templates).and_return(false)
        @provider.should_not_receive(:sv_dir)
        @provider.should_not_receive(:run_script)
        @provider.should_not_receive(:log)
        @provider.should_not_receive(:log_main_dir)
        @provider.should_not_receive(:log_run_script)
        @provider.send(:lsb_init).should_receive(:run_action).with(:create)
        @provider.send(:service_link).should_receive(:run_action).with(:create)
        @provider.run_action(:enable)
      end

      it 'creates a symlink from the sv dir to the service' do
        @provider.send(:service_link).path.should eq(::File.join(@service_dir_name))
        @provider.send(:service_link).to.should eq(::File.join(@sv_dir_name))
      end

      it 'enables the service with memoized resource creation methods' do
        @current_resource.stub!(:enabled).and_return(false)
        @provider.send(:sv_dir).should_receive(:run_action).with(:create)
        @provider.send(:run_script).should_receive(:run_action).with(:create)
        @provider.send(:log_dir).should_receive(:run_action).with(:create)
        @provider.send(:log_main_dir).should_receive(:run_action).with(:create)
        @provider.send(:log_run_script).should_receive(:run_action).with(:create)
        @provider.send(:lsb_init).should_receive(:run_action).with(:create)
        @provider.send(:service_link).should_receive(:run_action).with(:create)
        @provider.run_action(:enable)
      end

      context 'new resource conditionals' do
        before(:each) do
          @current_resource.stub!(:enabled).and_return(false)
          @provider.send(:sv_dir).stub!(:run_action).with(:create)
          @provider.send(:run_script).stub!(:run_action).with(:create)
          @provider.send(:lsb_init).stub!(:run_action).with(:create)
          @provider.send(:service_link).stub!(:run_action).with(:create)
          @provider.send(:log_dir).stub!(:run_action).with(:create)
          @provider.send(:log_main_dir).stub!(:run_action).with(:create)
          @provider.send(:log_run_script).stub!(:run_action).with(:create)
        end

        it 'doesnt create the log dir or run script if log is false' do
          @new_resource.stub!(:log).and_return(false)
          @provider.should_not_receive(:log)
          @provider.run_action(:enable)
        end

        it 'creates the env dir and config files if env is set' do
          @new_resource.stub!(:env).and_return({'PATH' => '/bin'})
          @provider.send(:env_dir).should_receive(:run_action).with(:create)
          @provider.send(:env_files).should_receive(:each).once
          @provider.run_action(:enable)
        end

        it 'creates the control dir and signal files if control is set' do
          @new_resource.stub!(:control).and_return(['s', 'u'])
          @provider.send(:control_dir).should_receive(:run_action).with(:create)
          @provider.send(:control_signal_files).should_receive(:each).once
          @provider.run_action(:enable)
        end

        it 'does not create the service_link on gentoo' do
          @node.automatic['platform'] = 'gentoo'
          @provider.should_not_receive(:service_link)
          @provider.run_action(:enable)
        end
      end

    end
  end
end
