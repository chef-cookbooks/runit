describe package('runit') do
  it { should be_installed }
end

describe command('ps -ef | grep -v grep | grep "runsvdir"') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/runsvdir/) }
end

describe file('/etc/service') do
  it { should be_directory }
  its('mode') { should cmp '0755' }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
end
