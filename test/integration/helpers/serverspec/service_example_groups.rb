require 'spec_helper'

shared_examples_for 'common runit_test services' do
  # no-svlog
  describe 'creates a service that doesnt use the svlog' do
    describe command('ps -ef | grep -v grep | grep "runsv no-svlog"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv no-svlog/) }
    end

    describe file('/etc/service/no-svlog/log') do
      it { should_not be_directory }
    end
  end

  # default-svlog
  describe 'creates a service that uses the default svlog' do
    describe command('ps -ef | grep -v grep | grep "runsv default-svlog"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv default-svlog/) }
    end

    describe file('/etc/service/default-svlog/log/run') do
      it { should be_mode 755 }
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
      its(:stdout) { should contain('gzip compressed data') }
    end
  end

  # checker
  describe 'creates a service that has a check script' do
    describe command('ps -ef | grep -v grep | grep "runsv checker"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv checker/) }
    end

    describe file('/etc/service/checker/check') do
      it { should be_mode 755 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end
  end

  # finisher
  describe 'creates a service that has a finish script' do
    describe command('ps -ef | grep -v grep | grep "runsv finisher"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv finisher/) }
    end

    describe file('/etc/service/finisher/finish') do
      it { should be_mode 755 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end
  end

  # env-files
  describe 'creates a service that uses env files' do
    describe command('ps -ef | grep -v grep | grep "runsv env-files"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv env-files/) }
    end

    describe file('/etc/service/env-files/env/PATH') do
      it { should be_mode 640 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      regexp = %r{\$PATH:/opt/chef/embedded/bin}
      its(:content) { should match regexp }
    end
  end

  # template-options
  describe 'creates a service that sets options for the templates' do
    describe command('ps -ef | grep -v grep | grep "runsv template-options"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv template-options/) }
    end

    describe file('/etc/service/template-options/run') do
      it { should be_mode 755 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      regexp = '# Options are delicious'
      its(:content) { should match regexp }
    end
  end

  # control-signals
  describe 'creates a service that uses control signal files' do
    describe command('ps -ef | grep -v grep | grep "runsv control-signals"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv control-signals/) }
    end

    describe file('/etc/service/control-signals/control/u') do
      it { should be_mode 755 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      regexp = 'control signal up'
      its(:content) { should match regexp }
    end
  end

  # runsvdir-floyd
  describe 'creates a runsvdir service for a normal user' do
    describe command('ps -ef | grep -v grep | grep "runsv runsvdir-floyd"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv runsvdir-floyd/) }
    end

    describe file('/etc/service/runsvdir-floyd/run') do
      it { should be_mode 755 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      regexp = %r{exec chpst -ufloyd runsvdir /home/floyd/service}
      its(:content) { should match regexp }
    end
  end

  # timer
  describe 'creates a service using sv_timeout' do
    describe command('ps -ef | grep -v grep | grep "runsv timer"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv timer/) }
    end
    # FIXME: add something here
  end

  # chatterbox
  describe 'creates a service using sv_verbose' do
    describe command('ps -ef | grep -v grep | grep "runsv chatterbox"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv chatterbox/) }
    end
    # FIXME: add something here
  end

  # yerba
  describe 'creates a service with differently named template files' do
    describe command('ps -ef | grep -v grep | grep "runsv yerba"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv yerba/) }
    end
    # FIXME: add something here
  end

  # yerba-alt
  describe 'creates a service with differently named run script template' do
    describe command('ps -ef | grep -v grep | grep "runsv yerba-alt"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv yerba-alt/) }
    end
    # FIXME: add something here
  end

  describe 'creates a service with a non-default log directory' do
    describe 'creates the log directory' do
      describe file('/var/log/yerba/matte') do
        it { should exist }
        it { should be_directory }
      end
    end

    describe 'writes a config file to the log directory' do
      describe file('/var/log/yerba/matte/config') do
        it { should exist }
      end
    end
  end

  # ayahuasca
  describe 'creates a service with a template from another cookbook' do
    describe command('ps -ef | grep -v grep | grep "runsv ayahuasca"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv ayahuasca/) }
    end
  end

  # exist-disabled
  describe 'creates a service that should exist but be disabled' do
    describe command('ps -ef | grep -v grep | grep "runsv control-signals"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should_not match(/runsv exist-disabled/) }
    end

    describe file('/etc/sv/exist-disabled/run') do
      it { should be_mode 755 }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end
  end

  # downed service
  describe 'creates and manages down file for service' do
    describe 'creates a service with a default state of down' do
      describe file('/etc/sv/downed-service-6702/run') do
        it { should be_mode 755 }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe file('/etc/service/downed-service-6702') do
        it { should be_symlink }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe file('/etc/sv/downed-service-6702/down') do
        it { should be_mode 644 }
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

    describe 'leaves existing downfile in place when down true -> false' do
      describe file('/etc/sv/un-downed-service/down') do
        it { should be_mode 644 }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe command('ps -ef | grep -v grep | grep "runsv un-downed-service"') do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match(/runsv un-downed-service/) }
      end
    end
    describe 'removes existing downfile when requested' do
      describe file('/etc/sv/un-downed-service-deleted/down') do
        it { should_not exist }
      end
    end
  end
end
