require 'spec_helper'

describe 'runit_service' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'ubuntu',
      version: '14.04',
      step_into: 'runit_service'
    ) do |node|
      node.set['runit']['version'] = '0.0'
    end.converge('runit_test::service')
  end

  let(:shellout) { double('shellout') }
  let(:sv_action_result) { double('service_action') }
  let(:sv_dir) { '/etc/sv' }
  let(:service_dir) { '/etc/service' }

  before do
    allow(Mixlib::ShellOut).to receive(:new).and_return(shellout)
    allow(shellout).to receive(:stdout).and_return('this the command output')
    allow(shellout).to receive(:live_stream).and_return(STDOUT)
    allow(shellout).to receive(:run_command).and_return(sv_action_result)
    allow(shellout).to receive(:error!).and_return(nil)
  end

  shared_examples_for 'runit_service' do
    it 'creates directory for service configuration under sv_dir' do
      expect(chef_run).to create_directory(service_svdir)
    end

    it 'creates the service directory' do
      expect(chef_run).to create_directory(service_dir)
    end

    it 'renders run script into service configuration directory' do
      expect(chef_run).to create_template(::File.join(service_svdir, 'run')).with(
        mode: '0755',
        owner: nil,
        group: nil,
        cookbook: 'runit_test',
        source: "sv-#{service.name}-run.erb",
        variables: { options: service_options }
      )
    end

    it 'creates directory for the service environment configuration' do
      expect(chef_run).to create_directory(::File.join(service_svdir, 'env'))
    end

    it 'creates directory for custom service control scripts' do
      expect(chef_run).to create_directory(::File.join(service_svdir, 'control'))
    end

    it 'links service configuration directory into service_dir' do
      expect(chef_run).to create_link(service_servicedir).with(
        to: service_svdir
      )
    end

    it 'waits for the service socket to appear' do
      expect(chef_run).to run_ruby_block("wait for #{service.name} service socket")
    end

    it 'enables the service' do
      expect(chef_run).to enable_runit_service(service.name)
    end
  end

  # The naming of these logging-related shared example groups is confusing because
  # the `default_logger` parameter defaults to false. Maybe in a future version we
  # rename this to something potentially less confusing, like embedded_logger?
  shared_examples_for 'runit_service with default_logger set to false' do
    it_behaves_like 'runit_service with default logging'

    let(:log_run_script) { chef_run.template(::File.join(service_svdir, 'log', 'run')) }

    it 'notifies the logger to restart when its run script is updated' do
      expect(log_run_script).to notify('ruby_block[restart_log_service]').to(:run).delayed
    end
  end

  shared_examples_for 'runit_service with default logging' do
    it_behaves_like 'runit_service'

    let(:log_config_tmpl) { chef_run.template(::File.join(service_svdir, 'log', 'config')) }

    it 'creates directories for the service logger' do
      expect(chef_run).to create_directory(::File.join(service_svdir, 'log'))
      expect(chef_run).to create_directory(::File.join(service_svdir, 'log', 'main'))
    end

    it 'renders logger run script into service log configuration directory' do
      expect(chef_run).to render_file(::File.join(service_svdir, 'log', 'run'))
    end

    it 'renders logger run script into service log configuration directory' do
      expect(chef_run).to render_file(::File.join(service_svdir, 'log', 'run'))
    end

    it 'renders logger config into service log configuration directory' do
      expect(chef_run).to create_template(::File.join(service_svdir, 'log', 'config')).with(
        mode: '00644',
        owner: nil,
        group: nil,
        cookbook: 'runit',
        source: 'log-config.erb',
        variables: { config: service }
      )
    end

    it 'notifies the logger to restart when its config is updated' do
      expect(log_config_tmpl).to notify('ruby_block[restart_log_service]').to(:run).delayed
    end
  end

  context 'with default attributes' do
    let(:service) { chef_run.runit_service('plain-defaults') }
    let(:service_svdir) { ::File.join(sv_dir, service.name) }
    let(:service_servicedir) { ::File.join(service_dir, service.name) }
    let(:service_options) { Hash.new }

    it_behaves_like 'runit_service with default_logger set to false'

    it 'does not zap extra env files' do
      expect(chef_run).to_not run_ruby_block('zap extra env files for plain-defaults service')
    end
  end

  context 'with the log attribute set to false' do
    let(:service) { chef_run.runit_service('no-svlog') }
    let(:service_svdir) { ::File.join(sv_dir, service.name) }
    let(:service_servicedir) { ::File.join(service_dir, service.name) }
    let(:service_options) { Hash.new }

    it_behaves_like 'runit_service'

    it 'does not create log directories' do
      expect(chef_run).to_not create_directory(::File.join(service_svdir, 'log'))
      expect(chef_run).to_not create_directory(::File.join(service_svdir, 'log', 'main'))
    end

    it 'enables the service' do
      expect(chef_run).to enable_runit_service(service.name)
    end
  end

  context 'with default_logger enabled' do
    let(:service) { chef_run.runit_service('default-svlog') }
    let(:service_svdir) { ::File.join(sv_dir, service.name) }
    let(:service_servicedir) { ::File.join(service_dir, service.name) }
    let(:service_options) { Hash.new }
    let(:log_run_script) { chef_run.file(::File.join(service_svdir, 'log', 'run')) }

    it_behaves_like 'runit_service with default logging'

    it 'creates a service with the default_logger attribute set to true' do
      expect(service.default_logger).to eq(true)
    end

    it 'creates default logger directory' do
      expect(chef_run).to create_directory("/var/log/#{service.name}")
    end

    it 'renders logger config into service log configuration directory with expected content' do
      log_config = ::File.join(service_svdir, 'log', 'config')
      expect(chef_run).to render_file(log_config).with_content(/^s10000$/)
      expect(chef_run).to render_file(log_config).with_content(/^n12$/)
      expect(chef_run).to render_file(log_config).with_content(/^!gzip$/)
    end

    it 'links log config into default logger directory' do
      expect(chef_run).to create_link("/var/log/#{service.name}/config").with(
        to: ::File.join(service_svdir, 'log', 'config')
      )
    end

    it 'notifies the logger to restart when its run script is updated' do
      expect(log_run_script).to notify('ruby_block[restart_log_service]').to(:run).delayed
    end
  end

  context 'with a check script' do
    let(:service) { chef_run.runit_service('checker') }
    let(:service_svdir) { ::File.join(sv_dir, service.name) }
    let(:service_servicedir) { ::File.join(service_dir, service.name) }
    let(:service_options) { Hash.new }

    it_behaves_like 'runit_service with default_logger set to false'

    it 'creates a service with check attribute set to true' do
      expect(service.check).to eq(true)
    end

    it 'renders a check script into the service configuration directory' do
      expect(chef_run).to create_template(::File.join(service_svdir, 'check')).with(
        mode: '00755',
        cookbook: 'runit_test',
        owner: nil,
        group: nil,
        source: "sv-#{service.name}-check.erb",
        variables: { options: {} }
      )
    end
  end

  context 'with a finish script' do
    let(:service) { chef_run.runit_service('finisher') }
    let(:service_svdir) { ::File.join(sv_dir, service.name) }
    let(:service_servicedir) { ::File.join(service_dir, service.name) }
    let(:service_options) { Hash.new }

    it_behaves_like 'runit_service with default_logger set to false'

    it 'creates a service with finish attribute set to true' do
      expect(service.finish).to eq(true)
    end

    it 'renders a finish script into the service configuration directory' do
      expect(chef_run).to create_template(::File.join(service_svdir, 'finish')).with(
        owner: nil,
        group: nil,
        mode: '00755',
        source: "sv-#{service.name}-finish.erb",
        cookbook: 'runit_test',
        variables: { options: {} }
      )
    end
  end

  context 'with environment attributes' do
    let(:service) { chef_run.runit_service('env-files') }
    let(:service_svdir) { ::File.join(sv_dir, service.name) }
    let(:service_servicedir) { ::File.join(service_dir, service.name) }
    let(:service_options) do
      { env_dir: '/etc/sv/env-files/env' }
    end

    it_behaves_like 'runit_service with default_logger set to false'

    it 'creates a service with a PATH environment variable' do
      expect(service.env).to have_key('PATH')
    end

    it 'writes files for environment variables into the service configuration directory' do
      expect(chef_run).to render_file(::File.join(service_svdir, 'env', 'PATH')).with_content(
        '$PATH:/opt/chef/embedded/bin'
      )
    end

    it 'sets the sensitive attribute on the env file resource' do
      expect(chef_run).to render_file(::File.join(service_svdir, 'env', 'PATH'))
        .with(sensitive: true)
    end

    it 'zaps any extra env files' do
      expect(chef_run).to run_ruby_block('zap extra env files for env-files service')
    end
  end

  context 'with template options' do
    let(:service) { chef_run.runit_service('template-options') }
    let(:service_svdir) { ::File.join(sv_dir, service.name) }
    let(:service_servicedir) { ::File.join(service_dir, service.name) }
    let(:service_options) do
      { raspberry: 'delicious' }
    end

    it_behaves_like 'runit_service with default_logger set to false'

    it 'renders the service run script with template options' do
      expect(chef_run).to render_file(::File.join(service_svdir, 'run')).with_content(/# Options are delicious/)
    end
  end

  context 'with custom control script' do
    let(:service) { chef_run.runit_service('control-signals') }
    let(:service_svdir) { ::File.join(sv_dir, service.name) }
    let(:service_servicedir) { ::File.join(service_dir, service.name) }
    let(:service_options) { Hash.new }
    let(:service_signal) { 'u' }

    it_behaves_like 'runit_service with default_logger set to false'

    it 'writes custom control script for signal' do
      expect(chef_run).to create_template(::File.join(service_svdir, 'control', service_signal)).with(
        owner: nil,
        group: nil,
        mode: '0755',
        source: "sv-#{service.name}-#{service_signal}.erb",
        cookbook: 'runit_test',
        variables: { options: {} }
      )
    end
  end
end
