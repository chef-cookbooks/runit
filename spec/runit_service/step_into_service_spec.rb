require 'spec_helper'

describe 'runit_service' do
  platform 'ubuntu'

  step_into :runit_service

  # we need to make sure we ahve the node['runit'] attribute space to prevent nilclass errors
  default_attributes['runit']['fake'] = nil

  describe 'with default properties' do
    recipe do
      runit_service 'test_service'
    end

    it 'creates service directory' do
      is_expected.to create_directory('/etc/sv/test_service')
    end

    it 'creates the service template' do
      is_expected.to create_template('/etc/sv/test_service/run')
    end

    it 'creates log directory in sv_dir' do
      is_expected.to create_directory('/etc/sv/test_service/log')
    end

    it 'creates main log directory' do
      is_expected.to create_directory('/etc/sv/test_service/log/main')
    end

    it 'creates the /var/log/SERVICE directory' do
      is_expected.to create_directory('/var/log/test_service')
    end
  end

  describe 'with sv_templates property set to false' do
    recipe do
      runit_service 'test_service' do
        sv_templates false
      end
    end

    it 'does not create the service directory' do
      is_expected.to_not create_directory('/etc/sv/test_service')
    end

    it 'does not create the service template' do
      is_expected.to_not create_template('/etc/sv/test_service/run')
    end
  end

  describe 'with log property set to false' do
    recipe do
      runit_service 'test_service' do
        log false
      end
    end

    it 'does not create the log directory in sv_dir ' do
      is_expected.to_not create_directory('/etc/sv/test_service/log')
    end

    it 'does not create the /var/log/SERVICE directory' do
      is_expected.to_not create_directory('/var/log/test_service')
    end
  end
end
