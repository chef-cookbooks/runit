module Helpers
    module Runit
        include MiniTest::Chef::Assertions
        include MiniTest::Chef::Context
        include MiniTest::Chef::Resources

        def assert_package_installed
            case node[:platform_family]
            when "debian"
                assert system('apt-cache policy runit | grep Installed | grep -v none')
            when "rhel"
                assert system('rpm -qa runit') 
            end
        end
    end
end
