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

    it 'creates service env directory' do
      is_expected.to create_directory('/etc/sv/test_service/env')
    end

    it 'creates service control directory' do
      is_expected.to create_directory('/etc/sv/test_service/control')
    end

    it 'does not template the service check file' do
      is_expected.to_not create_template('/etc/sv/test_service/check')
    end

    it 'templates the service run file' do
      is_expected.to create_template('/etc/sv/test_service/run')
    end

    it 'does not template the service finish file' do
      is_expected.to_not create_template('/etc/sv/test_service/finish')
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

    it 'templates the log config' do
      is_expected.to create_template('/etc/sv/test_service/log/config')
    end

    it 'links the config from the sv_dir into the /var/log dir' do
      is_expected.to create_link('/var/log/test_service/config')
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

    it 'does not template the log config' do
      is_expected.to_not create_template('/etc/sv/test_service/log/config')
    end

    it 'des not link the config from the sv_dir into the /var/log dir' do
      is_expected.to_not create_link('/var/log/test_service/config')
    end
  end

  describe 'with check property set to true' do
    recipe do
      runit_service 'test_service' do
        check true
      end
    end

    it 'templates the service check file' do
      is_expected.to create_template('/etc/sv/test_service/check')
    end
  end

  describe 'with finish property set to true' do
    recipe do
      runit_service 'test_service' do
        finish true
      end
    end

    it 'templates the service finish file' do
      is_expected.to create_template('/etc/sv/test_service/finish')
    end
  end
end
