require 'spec_helper'

describe 'runit_test::service on centos-5.8' do
  cached(:centos_58_service) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '5.8',
    # step_into: 'runit_service'
    ) do |node|
      node.set['runit']['version'] = '0.0'
    end.converge('runit_test::service')
  end

  # Resource in runit_test::service
  context 'compiling the test recipe' do
    it 'creates runit_service[plain-defaults]' do
      expect(centos_58_service).to enable_runit_service('plain-defaults')
    end

    it 'creates runit_service[no-svlog]' do
      expect(centos_58_service).to enable_runit_service('no-svlog')
    end

    it 'creates runit_service[default-svlog]' do
      expect(centos_58_service).to enable_runit_service('default-svlog')
    end

    it 'creates runit_service[checker]' do
      expect(centos_58_service).to enable_runit_service('checker')
    end

    it 'creates runit_service[finisher]' do
      expect(centos_58_service).to enable_runit_service('finisher')
    end

    it 'creates runit_service[env-files]' do
      expect(centos_58_service).to enable_runit_service('env-files')
    end

    it 'creates runit_service[template-options]' do
      expect(centos_58_service).to enable_runit_service('template-options')
    end

    it 'creates runit_service[control-signals]' do
      expect(centos_58_service).to enable_runit_service('control-signals')
    end

    it 'creates runit_service[runsvdir-floyd]' do
      expect(centos_58_service).to enable_runit_service('runsvdir-floyd')
    end

    it 'creates runit_service[timer]' do
      expect(centos_58_service).to enable_runit_service('timer')
    end

    it 'creates runit_service[chatterbox]' do
      expect(centos_58_service).to enable_runit_service('chatterbox')
    end

    it 'creates runit_service[floyds-app]' do
      expect(centos_58_service).to enable_runit_service('floyds-app')
    end

    it 'creates runit_service[yerba]' do
      expect(centos_58_service).to enable_runit_service('yerba')
    end

    it 'creates runit_service[yerba-alt]' do
      expect(centos_58_service).to enable_runit_service('yerba-alt')
    end

    it 'creates runit_service[ayahuasca]' do
      expect(centos_58_service).to enable_runit_service('ayahuasca')
    end

    it 'creates runit_service[exist-disabled]' do
      expect(centos_58_service).to disable_runit_service('exist-disabled')
    end
  end
end
