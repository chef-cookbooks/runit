name 'runit'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache 2.0'
description 'Installs runit and provides runit_service definition'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.8.0'

recipe 'runit', 'Installs and configures runit'

%w(ubuntu debian gentoo centos redhat amazon scientific oracle enterpriseenterprise zlinux).each do |os|
  supports os
end

depends 'packagecloud'
depends 'yum-epel'

source_url 'https://github.com/chef-cookbooks/runit' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/runit/issues' if respond_to?(:issues_url)

chef_version '>= 11.0' if respond_to?(:chef_version)
