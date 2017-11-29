if %w( redhat fedora ubuntu ).include? os[:name]
  # plain-defaults
  control 'creates a service with the defaults' do
    describe command('ps -ef | grep -v grep | grep "runsv plain-defaults"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv plain-defaults/) }
    end

    describe file('/etc/init.d/plain-defaults') do
      it { should be_symlink }
    end

    describe file('/etc/service/plain-defaults') do
      it { should be_symlink }
    end

    describe file('/etc/service/plain-defaults/run') do
      its('mode') { should cmp '00755' }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end

    describe file('/etc/service/plain-defaults/log') do
      it { should be_directory }
      its('mode') { should cmp '00755' }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end

    describe file('/etc/service/plain-defaults/log/run') do
      its('mode') { should cmp '00755' }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end

    describe file('/etc/service/plain-defaults/log/config') do
      it { should exist }
    end
  end

  # the following specs are a little different on debian vs other distros,
  # so they are not part of the common services example group

  # alternative-sv-bin
  control 'creates a service with an alternative sv_bin' do
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
  control 'creates a service running by a normal user in its runsvdir' do
    describe command('ps -ef | grep -v grep | grep "runsv floyds-app"') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match(/runsv floyds-app/) }
    end

    describe file('/etc/init.d/floyds-app') do
      it { should be_symlink }
    end

    describe file('/home/floyd/service/floyds-app') do
      it { should be_symlink }
    end

    describe file('/home/floyd/service/floyds-app/run') do
      its('mode') { should cmp '00755' }
      it { should be_owned_by 'floyd' }
      it { should be_grouped_into 'floyd' }
    end

    describe file('/home/floyd/service/floyds-app/log') do
      it { should be_directory }
      its('mode') { should cmp '00755' }
      it { should be_owned_by 'floyd' }
      it { should be_grouped_into 'floyd' }
    end

    describe file('/home/floyd/service/floyds-app/log/run') do
      its('mode') { should cmp '00755' }
      it { should be_owned_by 'floyd' }
      it { should be_grouped_into 'floyd' }
    end
  end
end
