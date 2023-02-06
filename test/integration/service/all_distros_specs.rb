# plain-defaults
control 'does not delete extra env files in env dir when the env attribute is empty' do
  describe file('/etc/service/plain-defaults/env/ZAP_TEST') do
    it { should exist }
    its(:content) { should eq '1' }
  end
end

# no-svlog
control 'creates a service that doesnt use the svlog' do
  describe command('ps -ef | grep -v grep | grep "runsv no-svlog"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv no-svlog/) }
  end

  describe file('/etc/service/no-svlog/log') do
    it { should_not be_directory }
  end
end

# default-svlog
control 'creates a service that uses the default svlog' do
  describe command('ps -ef | grep -v grep | grep "runsv default-svlog"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv default-svlog/) }
  end

  describe file('/etc/service/default-svlog/log/run') do
    its('mode') { should cmp '00755' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    regexp = %r{#!/bin/sh\nexec svlogd -tt /var/log/default-svlog}
    its(:content) { should match regexp }
  end

  # Send some random data to the service logs and wait for logs to be written
  describe command('dd if=/dev/urandom bs=5K count=10 | strings --bytes=1 | socat - "TCP4:127.0.0.1:6701" && sleep 2') do
    its(:exit_status) { should eq 0 }
  end

  describe command('file /var/log/default-svlog/*.s') do
    its(:stdout) { should match(/gzip compressed data/) }
  end
end

# checker
control 'creates a service that has a check script' do
  describe command('ps -ef | grep -v grep | grep "runsv checker"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv checker/) }
  end

  describe file('/etc/service/checker/check') do
    its('mode') { should cmp '00755' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end
end

# finisher
control 'creates a service that has a finish script' do
  describe command('ps -ef | grep -v grep | grep "runsv finisher"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv finisher/) }
  end

  describe file('/etc/service/finisher/finish') do
    its('mode') { should cmp '00755' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end
end

# env-files
control 'creates a service that uses env files' do
  describe command('ps -ef | grep -v grep | grep "runsv env-files"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv env-files/) }
  end

  describe file('/etc/service/env-files/env/PATH') do
    its('mode') { should cmp '00640' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    regexp = %r{\$PATH:/opt/chef/embedded/bin}
    its(:content) { should match regexp }
  end
end

control 'deletes unknown environment files in env dir when manage_env_dir is true' do
  describe file('/etc/service/env-files/env/ZAP_TEST') do
    it { should_not exist }
  end
end

# template-options
control 'creates a service that sets options for the templates' do
  describe command('ps -ef | grep -v grep | grep "runsv template-options"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv template-options/) }
  end

  describe file('/etc/service/template-options/run') do
    its('mode') { should cmp '00755' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    regexp = '# Options are delicious'
    its(:content) { should match regexp }
  end
end

# control-signals
control 'creates a service that uses control signal files' do
  describe command('ps -ef | grep -v grep | grep "runsv control-signals"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv control-signals/) }
  end

  describe file('/etc/service/control-signals/control/u') do
    its('mode') { should cmp '00755' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    regexp = 'control signal up'
    its(:content) { should match regexp }
  end
end

# runsvdir-floyd
control 'creates a runsvdir service for a normal user' do
  describe command('ps -ef | grep -v grep | grep "runsv runsvdir-floyd"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv runsvdir-floyd/) }
  end

  describe file('/etc/service/runsvdir-floyd/run') do
    its('mode') { should cmp '00755' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    regexp = %r{exec chpst -ufloyd runsvdir /home/floyd/service}
    its(:content) { should match regexp }
  end
end

# timer
control 'creates a service using sv_timeout' do
  describe command('ps -ef | grep -v grep | grep "runsv timer"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv timer/) }
  end
  # FIXME: add something here
end

# chatterbox
control 'creates a service using sv_verbose' do
  describe command('ps -ef | grep -v grep | grep "runsv chatterbox"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv chatterbox/) }
  end
  # FIXME: add something here
end

# yerba
control 'creates a service with differently named template files' do
  describe command('ps -ef | grep -v grep | grep "runsv yerba"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv yerba/) }
  end
  # FIXME: add something here
end

# yerba-alt
control 'creates a service with differently named run script template' do
  describe command('ps -ef | grep -v grep | grep "runsv yerba-alt"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv yerba-alt/) }
  end
  # FIXME: add something here
end

control 'creates a service with a non-default log directory' do
  describe file('/var/log/yerba/matte') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/var/log/yerba/matte/config') do
    it { should exist }
  end
end

# ayahuasca
control 'creates a service with a template from another cookbook' do
  describe command('ps -ef | grep -v grep | grep "runsv ayahuasca"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv ayahuasca/) }
  end
end

# exist-disabled
control 'creates a service that should exist but be disabled' do
  describe command('ps -ef | grep -v grep | grep "runsv control-signals"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should_not match(/runsv exist-disabled/) }
  end

  describe file('/etc/sv/exist-disabled/run') do
    its('mode') { should cmp '00755' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe file('/etc/sv/exist-disabled/supervise/ok') do
    it { should_not exist }
  end
end

# downed service
control 'creates a service with a default state of down' do
  describe file('/etc/sv/downed-service-6702/run') do
    its('mode') { should cmp '00755' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe file('/etc/service/downed-service-6702') do
    it { should be_symlink }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe file('/etc/sv/downed-service-6702/down') do
    its('mode') { should cmp '00644' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe command('ps -ef | grep -v grep | grep "runsv downed-service-6702"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv downed-service-6702/) }
  end

  describe command('netstat -tuplen | grep LISTEN | grep 6702') do
    its(:exit_status) { should eq 1 }
  end
end

control 'leaves existing downfile in place when down true -> false' do
  describe file('/etc/sv/un-downed-service/down') do
    its('mode') { should cmp '00644' }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end

  describe command('ps -ef | grep -v grep | grep "runsv un-downed-service"') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/runsv un-downed-service/) }
  end
end

control 'removes existing downfile when requested' do
  describe file('/etc/sv/un-downed-service-deleted/down') do
    it { should_not exist }
  end
end
