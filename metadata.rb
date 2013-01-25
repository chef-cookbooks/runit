name              "runit"
maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs runit and provides runit_service definition"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "0.16.3"

recipe "runit", "Installs and configures runit"

%w{ ubuntu debian gentoo centos redhat amazon scientific oracle enterpriseenterprise }.each do |os|
  supports os
end

attribute "runit",
  :display_name => "Runit",
  :description => "Hash of runit attributes",
  :type => "hash"

attribute "runit/sv_bin",
  :display_name => "Runit sv bin",
  :description => "Location of the sv binary",
  :default => "/usr/bin/sv"

attribute "runit/chpst_bin",
  :display_name => "Runit chpst bin",
  :description => "Location of the chpst binary",
  :default => "/usr/bin/chpst"

attribute "runit/service_dir",
  :display_name => "Runit service directory",
  :description => "Symlinks to services managed under runit",
  :default => "/etc/service"

attribute "runit/sv_dir",
  :display_name => "Runit sv directory",
  :description => "Location of services managed by runit",
  :default => "/etc/sv"

attribute "runit/executable",
  :display_name => "Runit executable",
  :description => "Location of the 'runit' binary",
  :default => "/sbin/runit"

attribute "runit/start",
  :display_name => "Runit Start",
  :description => "Command to start the master runit (runsvdir) service",
  :calculated => true

attribute "runit/stop",
  :display_name => "Runit Stop",
  :description => "Command to stop the master runit (runsvdir) service",
  :calculated => true

attribute "runit/reload",
  :display_name => "Runit Reload",
  :description => "Command to reload the master runit (runsvdir) service",
  :calculated => true
