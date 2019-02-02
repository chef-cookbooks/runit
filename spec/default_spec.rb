require 'spec_helper'

describe 'runit::default' do
  context 'on centos 6' do
    platform 'centos', '6'

    it 'includes the yum-epel::default recipe' do
      is_expected.to include_recipe('yum-epel::default')
    end

    it 'adds packagecloud_repo[imeyer/runit]' do
      is_expected.to add_packagecloud_repo('imeyer/runit')
    end

    it 'installs the runit package' do
      is_expected.to install_package('runit')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runsvdir')
      is_expected.to start_service('runsvdir')
    end
  end

  context 'on centos 7' do
    platform 'centos', '7'

    it 'includes the yum-epel::default recipe' do
      is_expected.to_not include_recipe('yum-epel::default')
    end

    it 'adds packagecloud_repo[imeyer/runit]' do
      is_expected.to add_packagecloud_repo('imeyer/runit')
    end

    it 'installs the runit package' do
      is_expected.to install_package('runit')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runsvdir-start')
      is_expected.to start_service('runsvdir-start')
    end
  end

  context 'on Amazon Linux 201X' do
    platform 'amazon', '2016'

    it 'includes the yum-epel::default recipe' do
      is_expected.to_not include_recipe('yum-epel::default')
    end

    it 'adds packagecloud_repo[imeyer/runit]' do
      is_expected.to add_packagecloud_repo('imeyer/runit').with(force_os: 'rhel', force_dist: '6', type: 'rpm')
    end

    it 'installs the runit package' do
      is_expected.to install_package('runit')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runsvdir')
      is_expected.to start_service('runsvdir')
    end
  end

  context 'on Amazon Linux 2' do
    platform 'amazon', '2'

    it 'includes the yum-epel::default recipe' do
      is_expected.to_not include_recipe('yum-epel::default')
    end

    it 'adds packagecloud_repo[imeyer/runit]' do
      is_expected.to add_packagecloud_repo('imeyer/runit').with(force_os: 'rhel', force_dist: '7', type: 'rpm')
    end

    it 'installs the runit package' do
      is_expected.to install_package('runit')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runsvdir-start')
      is_expected.to start_service('runsvdir-start')
    end
  end

  context 'on Ubuntu 14.04' do
    platform 'ubuntu', '14.04'

    it 'installs the runit package' do
      is_expected.to install_package('runit')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runsvdir')
      is_expected.to start_service('runsvdir')
    end
  end

  context 'on Ubuntu 16.04' do
    platform 'ubuntu', '16.04'

    it 'installs the runit package' do
      is_expected.to install_package('runit')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runit')
      is_expected.to start_service('runit')
    end
  end

  context 'on Ubuntu 18.04' do
    platform 'ubuntu', '18.04'

    it 'installs the runit package' do
      is_expected.to install_package('runit-systemd')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runit')
      is_expected.to start_service('runit')
    end
  end

  context 'on Debian 8' do
    platform 'Debian', '8'

    it 'installs the runit package' do
      is_expected.to install_package('runit')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runit')
      is_expected.to start_service('runit')
    end
  end

  context 'on Debian 9' do
    platform 'debian', '9'

    it 'installs the runit package' do
      is_expected.to install_package('runit-systemd')
    end

    it 'starts and enabled the correct runit service' do
      is_expected.to enable_service('runit')
      is_expected.to start_service('runit')
    end
  end
end
