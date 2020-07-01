name 'runit'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache-2.0'
description 'Installs runit and provides runit_service resource'
version '5.1.6'

%w(ubuntu debian centos redhat amazon scientific oracle enterpriseenterprise zlinux).each do |os|
  supports os
end

depends 'packagecloud'
depends 'yum-epel'

source_url 'https://github.com/chef-cookbooks/runit'
issues_url 'https://github.com/chef-cookbooks/runit/issues'
chef_version '>= 14.0'
