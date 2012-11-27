#
# Cookbook Name:: runit
# Recipe:: default
#
# Copyright 2008-2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# TODO: Try to make this operate on a value_for_platform_family basis
# Note: Debian and Ubuntu handle it differently
# Consider: moving to an attribute?

execute "start-runsvdir" do
  command value_for_platform(
    "debian" => { "default" => "runsvdir-start" },
    "ubuntu" => { "default" => "start runsvdir" },
    "gentoo" => { "default" => "/etc/init.d/runit-start start" },
  )
  action :nothing
end

execute "runit-hup-init" do
  command "telinit q"
  only_if "grep ^SV /etc/inittab"
  action :nothing
end

case node["platform_family"]
when "rhel"
  # Prepare build environment
  packages = %w{rpm-build rpmdevtools unzip}
  packages.each do |p|
    package p
  end

  if node["platform_version"].to_i >= 6
    package "glibc-static"
  else
    package "buildsys-macros"
  end

  remote_file "#{Chef::Config[:file_cache_path]}/master.zip" do
    source "https://github.com/imeyer/runit-rpm/archive/master.zip"
    not_if "rpm -qa | grep -q '^runit'"
    notifies :run, "bash[rhel_build_install]", :immediately
  end

  bash "rhel_build_install" do
    user "root"
    cwd "#{Chef::Config[:file_cache_path]}" 
    code <<-EOH
      unzip master
      cd runit-rpm-master
      ./build.sh
      rpm -i ~/rpmbuild/RPMS/*/*.rpm
    EOH
    action :nothing
  end

when "debian","gentoo"

  package "runit" do
    action :install
    if platform?("ubuntu", "debian")
      response_file "runit.seed"
    end
# This is ugly!  Maybe make it an attribute?
    notifies value_for_platform(
      "debian" => { "4.0" => :run, "default" => :nothing  },
      "ubuntu" => {
        "default" => :nothing,
        "9.04" => :run,
        "8.10" => :run,
        "8.04" => :run },
      "gentoo" => { "default" => :run }
    ), resources(:execute => "start-runsvdir"), :immediately
# Same here? Why nothing for non squeeze/sid? Gentoo?
    notifies value_for_platform(
      "debian" => { "squeeze/sid" => :run, "default" => :nothing },
      "default" => :nothing
    ), resources(:execute => "runit-hup-init"), :immediately
  end

# 8.04 is last supported LTS, versions previous are out of Canonical support.
# Do we want to maintain this support forever?
  if node["platform"] =~ /ubuntu/i && node["platform_version"].to_f <= 8.04
    cookbook_file "/etc/event.d/runsvdir" do
      source "runsvdir"
      mode 0644
      notifies :run, resources(:execute => "start-runsvdir"), :immediately
      only_if do ::File.directory?("/etc/event.d") end
    end
  end
# TODO: Move or not move?
  if platform? "gentoo"
    template "/etc/init.d/runit-start" do
      source "runit-start.sh.erb"
      mode 0755
    end
  end
end
