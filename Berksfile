source 'https://supermarket.chef.io'

metadata

group :integration do
  cookbook 'apt'
  cookbook 'yum'
  cookbook 'yum-epel'
end

cookbook 'runit_test', path: 'test/cookbooks/runit_test'
cookbook 'runit_other_test', path: 'test/cookbooks/runit_other_test'
