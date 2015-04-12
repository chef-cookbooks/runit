require 'serverspec'

set :backend, :exec

puts "os: #{os}"

if %w( redhat fedora debian ubuntu ).include? os[:family]
  describe package('runit') do
    it { should be_installed }
  end

  describe service('runsvdir') do
    it { should be_running }
  end

  describe file('/etc/service') do
    it { should be_directory }
    it { should be_mode 755 }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
  end
end
