#
# Author:: Joshua Timberman <joshua@chef.io>
# Author:: Seth Chisamore <schisamo@chef.io>
#
# Copyright:: Copyright (c) 2012, Chef Software, Inc. <legal@chef.io>
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

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
require 'spec_helper'

describe Chef::Provider::Service::Runit do

  subject(:provider) { Chef::Provider::Service::Runit.new(new_resource, run_context) }

  let(:sv_bin) { '/usr/bin/sv' }
  let(:service_name) { 'getty.service' }
  let(:service_dir) { '/etc/service' }
  let(:service_dir_name) { "#{service_dir}/#{service_name}" }
  let(:service_status_command) { "#{sv_bin} status #{service_dir}/#{service_name}" }
  let(:run_script) { File.join(service_dir, service_name, 'run') }
  let(:log_run_script) { File.join(service_dir, service_name, 'log', 'run') }
  let(:log_config_file) { File.join(service_dir, service_name, 'log', 'config') }

  let(:node) do
    node = Chef::Node.new
    node.automatic['platform'] = 'ubuntu'
    node.automatic['platform_version'] = '12.04'
    node.set['runit']['sv_bin'] = sv_bin
    node
  end
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:new_resource) { Chef::Resource::RunitService.new('getty.service') }
  let(:current_resource) { Chef::Resource::RunitService.new('getty.service') }

  before do
    provider.stub(:load_current_resource).and_return(current_resource)
    provider.new_resource = new_resource
    provider.current_resource = current_resource
  end

  describe '#load_current_resource' do

    before do
      provider.unstub(:load_current_resource)
    end

    describe 'runit is not installed' do
      it 'raises an exception' do
        ->{ provider.load_current_resource }.should raise_error
      end
    end

    context 'runit is installed' do

      let(:status_output) { "run: #{service_name}: (pid 29018) 3s; run: log: (pid 24470) 46882s" }

      before do
        File.stub(:exist?).with(sv_bin).and_return(true)
        File.stub(:executable?).with(sv_bin).and_return(true)
        provider.stub(:shell_out)
          .with(service_status_command)
          .and_return(double('ouput', :stdout => status_output, :exitstatus => 0))
        provider.load_current_resource
      end

      describe 'parsing sv status output' do

        context 'returns a pid' do
          let(:status_output) { "run: #{service_name}: (pid 29018) 3s; run: log: (pid 24470) 46882s" }

          it 'sets resource running state to true' do
            provider.current_resource.running.should be_true
          end
        end

        context 'returns an empty pid' do
          let(:status_output) { "down: #{service_name}: 2s, normally up; run: log: (pid 24470) 46250s" }

          it 'sets resource running state to false' do
            provider.current_resource.running.should be_false
          end
        end
      end

      describe 'checking for service run script' do
        context 'service run script is present in service_dir' do
          before do
            ::File.stub(:exists?).with(run_script).and_return(true)
            provider.load_current_resource
          end

          it 'sets resource enabled state to true' do
            provider.current_resource.enabled.should be_true
          end
        end

        context 'service run script is missing' do
          before do
            ::File.stub(:exists?).with(run_script).and_return(false)
            provider.load_current_resource
          end

          it 'sets resource enabled state to false' do
            provider.current_resource.enabled.should be_false
          end
        end
      end

      describe 'set the current environment' do
        let(:sv_env_dir_name) { ::File.join(new_resource.sv_dir, new_resource.service_name, 'env') }
        context 'present env dir' do
          before do
            ::File.stub(:directory?).with(sv_env_dir_name).and_return(true)
            ::Dir.stub(:glob).with(::File.join(sv_env_dir_name,'*')).and_return([::File.join(sv_env_dir_name,'FOO')])
            ::IO.stub(:read).with(::File.join(sv_env_dir_name,'FOO')).and_return('bar')
            provider.load_current_resource
          end
          it 'should load environment from env dir' do
            provider.current_resource.env.should eq({'FOO' => 'bar'})
          end
        end
        context 'no env dir' do
          before do
            ::File.stub(:directory?).with(sv_env_dir_name).and_return(false)
          end
          it 'should set env to an empty hash' do
            provider.current_resource.env.should eq({})
          end
        end
      end
    end
  end

  describe 'actions' do
    describe 'start' do

      before do
        provider.current_resource.running(false)
      end

      %w{start up once cont}.each do |action|
        it "sends the #{action} command to the sv binary" do
          provider.should_receive(:shell_out!).with("#{sv_bin} #{action} #{service_dir_name}")
          provider.run_action(action.to_sym)
        end
      end
    end

    describe 'action_usr1' do
      it 'sends the usr1 signal to the sv binary' do
        provider.should_receive(:shell_out!).with("#{sv_bin} 1 #{service_dir_name}")
        provider.run_action(:usr1)
      end
    end

    describe 'action_usr2' do
      it 'sends the usr2 signal to the sv binary' do
        provider.should_receive(:shell_out!).with("#{sv_bin} 2 #{service_dir_name}")
        provider.run_action(:usr2)
      end
    end

    describe 'actions that manage a running service' do
      before do
        provider.current_resource.running(true)
      end

      %w{stop down restart hup int term kill quit}.each do |action|
        it "sends the '#{action}' command to the sv binary" do
          provider.should_receive(:shell_out!).with("#{sv_bin} #{action} #{service_dir_name}")
          provider.run_action(action.to_sym)
        end
      end

      describe 'action_reload' do
        it "sends the 'force-reload' command to the sv binary" do
          provider.should_receive(:shell_out!).with("#{sv_bin} force-reload #{service_dir_name}")
          provider.run_action(:reload)
        end
      end
    end

    describe 'action_disable' do
      before do
        provider.current_resource.enabled(true)
      end

      it 'disables the service by running the down command and removing the symlink' do
        provider.should_receive(:shell_out).with("#{sv_bin} down #{service_dir_name}")
        FileUtils.should_receive(:rm).with(service_dir_name)
        provider.run_action(:disable)
      end
    end

    describe 'action_enable' do
      let(:sv_dir_name) { ::File.join(new_resource.sv_dir, new_resource.service_name) }

      before(:each) do
        provider.current_resource.enabled(false)
        FileTest.stub(:pipe?).with("#{service_dir_name}/supervise/ok").and_return(true)
        FileTest.stub(:pipe?).with("#{service_dir_name}/log/supervise/ok").and_return(true)
      end

      it 'creates the sv_dir directory' do
        provider.send(:sv_dir).path.should eq(sv_dir_name)
        provider.send(:sv_dir).recursive.should be_true
        provider.send(:sv_dir).owner.should eq(new_resource.owner)
        provider.send(:sv_dir).group.should eq(new_resource.group)
        provider.send(:sv_dir).mode.should eq('00755')
      end

      it 'creates env directory and files' do
        new_resource.env('PATH' => '$PATH:/usr/local/bin')
        provider.send(:env_files)[0].path.should eq(::File.join(sv_dir_name, 'env', 'PATH'))
        provider.send(:env_files)[0].owner.should eq(new_resource.owner)
        provider.send(:env_files)[0].group.should eq(new_resource.group)
        provider.send(:env_files)[0].content.should eq('$PATH:/usr/local/bin')
      end

      it 'removes env files that are not referenced in env' do
        provider.current_resource.stub(:env).and_return('FOO' => 'Bar')
        new_resource.stub(:env).and_return('PATH' => '/bin')
        delete = provider.send(:env_files).select { |x| x.action.include? :delete }
        delete.first.path.should eq(::File.join(sv_dir_name, 'env', 'FOO'))
      end

      it 'creates a finish script as a template if finish_script parameter is true' do
        provider.send(:finish_script).path.should eq(::File.join(sv_dir_name, 'finish'))
        provider.send(:finish_script).owner.should eq(new_resource.owner)
        provider.send(:finish_script).group.should eq(new_resource.group)
        provider.send(:finish_script).mode.should eq(00755)
        provider.send(:finish_script).source.should eq("sv-#{new_resource.finish_script_template_name}-finish.erb")
        provider.send(:finish_script).cookbook.should be_empty
      end

      it 'creates control directory and signal files' do
        provider.send(:control_dir).path.should eq(::File.join(sv_dir_name, 'control'))
        provider.send(:control_dir).owner.should eq(new_resource.owner)
        provider.send(:control_dir).group.should eq(new_resource.group)
        provider.send(:control_dir).mode.should eq(00755)
        new_resource.control(['s'])
        provider.send(:control_signal_files)[0].path.should eq(::File.join(sv_dir_name, 'control', 's'))
        provider.send(:control_signal_files)[0].owner.should eq(new_resource.owner)
        provider.send(:control_signal_files)[0].group.should eq(new_resource.group)
        provider.send(:control_signal_files)[0].mode.should eq(00755)
        provider.send(:control_signal_files)[0].source.should eq("sv-#{new_resource.control_template_names['s']}-s.erb")
        provider.send(:control_signal_files)[0].cookbook.should be_empty
      end

      it 'creates a symlink for LSB script compliance unless the platform is debian' do
        node.automatic['platform'] = 'not_debian'
        provider.send(:lsb_init).path.should eq(::File.join('/etc', 'init.d', new_resource.service_name))
        provider.send(:lsb_init).to.should eq(sv_bin)
      end

      it 'creates an init script as a template for LSB compliance if the platform is debian' do
        node.automatic['platform'] = 'debian'
        provider.send(:lsb_init).path.should eq(::File.join('/etc', 'init.d', new_resource.service_name))
        provider.send(:lsb_init).owner.should eq('root')
        provider.send(:lsb_init).group.should eq('root')
        provider.send(:lsb_init).mode.should eq(00755)
        provider.send(:lsb_init).cookbook.should eq('runit')
        provider.send(:lsb_init).source.should eq('init.d.erb')
        provider.send(:lsb_init).variables.should have_key(:name)
        provider.send(:lsb_init).variables[:name].should eq(new_resource.service_name)
      end

      it 'does not create anything in the sv_dir if it is nil or false' do
        current_resource.stub(:enabled).and_return(false)
        new_resource.stub(:sv_templates).and_return(false)
        provider.should_not_receive(:sv_dir)
        provider.should_not_receive(:log)
        provider.should_not_receive(:log_main_dir)
      end

      describe 'when sv_timeout is set' do
        before do
          new_resource.sv_timeout(60)
        end

        %w{start up once cont}.each do |action|
          it "pass a timeout argument on #{action} action to the sv binary" do
            provider.current_resource.running(false)
            provider.should_receive(:shell_out!).with("#{sv_bin} -w '60' #{action} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

        {
          :usr1 => 1,
          :usr2 => 2,
          :reload => 'force-reload',
        }.each do |action, arg|
          it "pass a timeout argument on #{action} action to the sv binary" do
            provider.current_resource.running(true)
            provider.should_receive(:shell_out!).with("#{sv_bin} -w '60' #{arg} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

        %w{stop down restart hup int term kill quit}.each do |action|
          it "pass a timeout argument on #{action} action to the sv binary" do
            provider.current_resource.running(true)
            provider.should_receive(:shell_out!).with("#{sv_bin} -w '60' #{action} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

      end

      describe 'when sv_verbose is true' do
        before do
          new_resource.sv_verbose(true)
        end

        %w{start up once cont}.each do |action|
          it "pass a verbose argument on #{action} action to the sv binary" do
            provider.current_resource.running(false)
            provider.should_receive(:shell_out!).with("#{sv_bin} -v #{action} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

        {
          :usr1 => 1,
          :usr2 => 2,
          :reload => 'force-reload',
        }.each do |action, arg|
          it "pass a verbose argument on #{action} action to the sv binary" do
            provider.current_resource.running(true)
            provider.should_receive(:shell_out!).with("#{sv_bin} -v #{arg} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

        %w{stop down restart hup int term kill quit}.each do |action|
          it "pass a verbose argument on #{action} action to the sv binary" do
            provider.current_resource.running(true)
            provider.should_receive(:shell_out!).with("#{sv_bin} -v #{action} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

      end

      describe 'when both sv_timeout and sv_verbose are set' do
        before do
          new_resource.sv_timeout(60)
          new_resource.sv_verbose(true)
        end

        %w{ start up once cont }.each do |action|
          it "pass both timeout and verbose arguments on #{action} action to the sv binary" do
            provider.current_resource.running(false)
            provider.should_receive(:shell_out!).with("#{sv_bin} -w '60' -v #{action} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

        {
          :usr1 => 1,
          :usr2 => 2,
          :reload => 'force-reload',
        }.each do |action, arg|
          it "pass both timeout and verbose arguments on #{action} action to the sv binary" do
            provider.current_resource.running(true)
            provider.should_receive(:shell_out!).with("#{sv_bin} -w '60' -v #{arg} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

        %w{stop down restart hup int term kill quit}.each do |action|
          it "pass both timeout and verbose arguments argument on #{action} action to the sv binary" do
            provider.current_resource.running(true)
            provider.should_receive(:shell_out!).with("#{sv_bin} -w '60' -v #{action} #{service_dir_name}")
            provider.run_action(action.to_sym)
          end
        end

      end

      it 'creates a symlink from the sv dir to the service' do
        provider.send(:service_link).path.should eq(service_dir_name)
        provider.send(:service_link).to.should eq(sv_dir_name)
      end

      it 'enables the service with memoized resource creation methods' do
        current_resource.stub(:enabled).and_return(false)
      end

      describe 'run_script template changes' do
        before do
          provider.stub(:configure_service)
          provider.stub(:enable_service)
        end
      end

      describe 'log_run_script template changes' do
        before do
          provider.stub(:configure_service)
          provider.stub(:enable_service)
        end

        context 'log_run_script is updated' do
          before { provider.send(:log_run_script).stub(:updated_by_last_action?).and_return(true) }

          context 'restart_on_update attribute is true' do
            before { new_resource.restart_on_update(true) }
          end

          context 'restart_on_update attribute is false' do
            before { new_resource.restart_on_update(false) }

            it 'does not restart the service' do
              provider.should_not_receive(:restart_log_service)
              provider.run_action(:enable)
            end
          end
        end

        context 'log_run_script is unchanged' do
          before { provider.send(:log_run_script).stub(:updated_by_last_action?).and_return(false) }

          context 'restart_on_update attribute is true' do
            before { new_resource.restart_on_update(true) }

            it 'does not restart the service' do
              provider.should_not_receive(:restart_log_service)
            end
          end

          context 'restart_on_update attribute is false' do
            before { new_resource.restart_on_update(false) }

            it 'does not restart the service' do
              provider.should_not_receive(:restart_log_service)
              provider.run_action(:enable)
            end
          end
        end
      end

      describe 'log_config_file template changes' do
        before do
          provider.stub(:configure_service)
          provider.stub(:enable_service)
        end

        context 'log_config_file is updated' do
          before { provider.send(:log_config_file).stub(:updated_by_last_action?).and_return(true) }

          context 'restart_on_update attribute is true' do
            before { new_resource.restart_on_update(true) }
          end

          context 'restart_on_update attribute is false' do
            before { new_resource.restart_on_update(false) }

            it 'does not restart the service' do
              provider.should_not_receive(:restart_log_service)
              provider.run_action(:enable)
            end
          end
        end

        context 'log_config_file is unchanged' do
          before { provider.send(:log_config_file).stub(:updated_by_last_action?).and_return(false) }

          context 'restart_on_update attribute is true' do
            before { new_resource.restart_on_update(true) }

            it 'does not restart the service' do
              provider.should_not_receive(:restart_log_service)
            end
          end

          context 'restart_on_update attribute is false' do
            before { new_resource.restart_on_update(false) }

            it 'does not restart the service' do
              provider.should_not_receive(:restart_log_service)
              provider.run_action(:enable)
            end
          end
        end
      end

      context 'new resource conditionals' do
        before(:each) do
          current_resource.stub(:enabled).and_return(false)
        end

        it 'doesnt create the log dir or run script if log is false' do
          new_resource.stub(:log).and_return(false)
          provider.should_not_receive(:log)
        end

        it 'creates the env dir and config files if env is set' do
          new_resource.stub(:env).and_return('PATH' => '/bin')
        end

        it 'creates the control dir and signal files if control is set' do
          new_resource.stub(:control).and_return %w{ s u }
        end
      end
    end
  end
end
