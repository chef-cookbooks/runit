require 'spec_helper'

describe 'runit::default on centos 6' do
  cached(:centos6_default) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '6.9'
    ).converge('runit::default')
  end

  it 'includes the yum-epel::default recipe' do
    expect(centos6_default).to include_recipe('yum-epel::default')
  end

  it 'adds packagecloud_repo[imeyer/runit]' do
    expect(centos6_default).to add_packagecloud_repo('imeyer/runit')
  end

  it 'installs the runit package' do
    expect(centos6_default).to install_package('runit')
  end

  it 'starts and enabled the correct runit service' do
    expect(centos6_default).to enable_service('runsvdir')
    expect(centos6_default).to start_service('runsvdir')
  end
end

describe 'runit::default on centos 7' do
  cached(:centos7_default) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '7.4.1708'
    ).converge('runit::default')
  end

  it 'does not include the yum-epel::default recipe' do
    expect(centos7_default).to_not include_recipe('yum-epel::default')
  end

  it 'adds packagecloud_repo[imeyer/runit]' do
    expect(centos7_default).to add_packagecloud_repo('imeyer/runit')
  end

  it 'installs the runit package' do
    expect(centos7_default).to install_package('runit')
  end

  it 'starts and enabled the correct runit service' do
    expect(centos7_default).to enable_service('runsvdir-start')
    expect(centos7_default).to start_service('runsvdir-start')
  end
end

describe 'runit::default on amazon linux' do
  cached(:amazon_default) do
    ChefSpec::SoloRunner.new(
      platform: 'amazon',
      version: '2017.03'
    ).converge('runit::default')
  end

  it 'does not include the yum-epel::default recipe' do
    expect(amazon_default).to_not include_recipe('yum-epel::default')
  end

  it 'adds packagecloud_repo[imeyer/runit]' do
    expect(amazon_default).to add_packagecloud_repo('imeyer/runit')
  end

  it 'installs the runit package' do
    expect(amazon_default).to install_package('runit')
  end

  it 'starts and enabled the correct runit service' do
    expect(amazon_default).to enable_service('runsvdir')
    expect(amazon_default).to start_service('runsvdir')
  end
end

describe 'runit::default on ubuntu 14.04' do
  cached(:ubuntu14_default) do
    ChefSpec::SoloRunner.new(
      platform: 'ubuntu',
      version: '14.04'
    ).converge('runit::default')
  end

  it 'installs the runit package' do
    expect(ubuntu14_default).to install_package('runit')
  end

  it 'starts and enabled the correct runit service' do
    expect(ubuntu14_default).to enable_service('runsvdir')
    expect(ubuntu14_default).to start_service('runsvdir')
  end
end

describe 'runit::default on ubuntu 16.04' do
  cached(:ubuntu16_default) do
    ChefSpec::SoloRunner.new(
      platform: 'ubuntu',
      version: '16.04'
    ).converge('runit::default')
  end

  it 'installs the runit package' do
    expect(ubuntu16_default).to install_package('runit')
  end

  it 'starts and enabled the correct runit service' do
    expect(ubuntu16_default).to enable_service('runit')
    expect(ubuntu16_default).to start_service('runit')
  end
end

describe 'runit::default on debian 7' do
  cached(:debian7_default) do
    ChefSpec::SoloRunner.new(
      platform: 'debian',
      version: '7.11'
    ).converge('runit::default')
  end

  it 'installs the runit package' do
    expect(debian7_default).to install_package('runit')
  end

  it 'does not start or enabled the a runit service' do
    expect(debian7_default).to_not enable_service('runit')
    expect(debian7_default).to_not start_service('runit')
  end
end

describe 'runit::default on debian 8' do
  cached(:debian8_default) do
    ChefSpec::SoloRunner.new(
      platform: 'debian',
      version: '8.9'
    ).converge('runit::default')
  end

  it 'installs the runit package' do
    expect(debian8_default).to install_package('runit')
  end

  it 'starts and enabled the correct runit service' do
    expect(debian8_default).to enable_service('runit')
    expect(debian8_default).to start_service('runit')
  end
end

describe 'runit::default on debian 9' do
  cached(:debian9_default) do
    ChefSpec::SoloRunner.new(
      platform: 'debian',
      version: '9.2'
    ).converge('runit::default')
  end

  it 'installs the runit-systemd package' do
    expect(debian9_default).to install_package('runit-systemd')
  end

  it 'starts and enabled the correct runit service' do
    expect(debian9_default).to enable_service('runit')
    expect(debian9_default).to start_service('runit')
  end
end
