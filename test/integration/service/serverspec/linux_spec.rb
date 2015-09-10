require 'spec_helper'
require 'service_example_groups'

if %w( redhat fedora ubuntu ).include? os[:family]

  describe "runit_test::service on #{os}" do
    # plain-defaults
    describe 'creates a service with the defaults' do
      describe command('ps -ef | grep -v grep | grep "runsv plain-defaults"') do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match(/runsv plain-defaults/) }
      end

      describe file('/etc/init.d/plain-defaults') do
        it { should be_symlink }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe file('/etc/service/plain-defaults') do
        it { should be_symlink }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe file('/etc/service/plain-defaults/run') do
        it { should be_mode 755 }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe file('/etc/service/plain-defaults/log') do
        it { should be_directory }
        it { should be_mode 755 }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe file('/etc/service/plain-defaults/log/run') do
        it { should be_mode 755 }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end
    end

    it_behaves_like 'common runit_test services'

    # the following specs are a little different on debian vs other distros,
    # so they are not part of the common services example group

    # alternative-sv-bin
    describe 'creates a service with an alternative sv_bin' do
      describe command('ps -ef | grep -v grep | grep "runsv alternative-sv-bin"') do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match(/runsv alternative-sv-bin/) }
      end

      describe file('/etc/init.d/alternative-sv-bin') do
        it { should be_symlink }
        it { should be_linked_to('/usr/local/bin/sv') }
      end
    end

    # floyds-app
    describe 'creates a service running by a normal user in its runsvdir' do
      describe command('ps -ef | grep -v grep | grep "runsv floyds-app"') do
        its(:exit_status) { should eq 0 }
        its(:stdout) { should match(/runsv floyds-app/) }
      end

      describe file('/etc/init.d/floyds-app') do
        it { should be_symlink }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe file('/home/floyd/service/floyds-app') do
        it { should be_symlink }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end

      describe file('/home/floyd/service/floyds-app/run') do
        it { should be_mode 755 }
        it { should be_owned_by 'floyd' }
        it { should be_grouped_into 'floyd' }
      end

      describe file('/home/floyd/service/floyds-app/log') do
        it { should be_directory }
        it { should be_mode 755 }
        it { should be_owned_by 'floyd' }
        it { should be_grouped_into 'floyd' }
      end

      describe file('/home/floyd/service/floyds-app/log/run') do
        it { should be_mode 755 }
        it { should be_owned_by 'floyd' }
        it { should be_grouped_into 'floyd' }
      end
    end
  end
end
