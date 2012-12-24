require File.expand_path('../support/helpers.rb', __FILE__)

describe "runit::default" do
    include Helpers::Runit

    it 'has been installed' do
        assert_package_installed
    end
end
