name 'runit'
maintainer 'Heavy Water Operations, LLC.'
maintainer_email 'support@hw-ops.com'
license 'Apache 2.0'
description 'Installs runit and provides runit_service definition'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.7.7'

recipe 'runit', 'Installs and configures runit'

%w(ubuntu debian gentoo centos redhat amazon scientific oracle enterpriseenterprise).each do |os|
  supports os
end

depends 'packagecloud'
depends 'yum-epel'

source_url 'https://github.com/hw-cookbooks/runit' if respond_to?(:source_url)
issues_url 'https://github.com/hw-cookbooks/runit/issues' if respond_to?(:issues_url)
