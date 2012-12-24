#
# Cookbook Name:: runit
# Attribute File:: sv_bin
#
# Copyright 2008-2009, Opscode, Inc.
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

case platform_family
when "debian"
  set["runit"]["sv_bin"] = "/usr/bin/sv"
  set["runit"]["chpst_bin"] = "/usr/bin/chpst"
  set["runit"]["service_dir"] = "/etc/service"
  set["runit"]["sv_dir"] = "/etc/sv"
  set["runit"]["executable"] = "/sbin/runit"
  if platform=="debian"
    set["runit"]["start"] = "runsvdir-start"
    set["runit"]["stop"] = ""
    set["runit"]["reload"] = ""
  elsif platform=="ubuntu"
    set["runit"]["start"] = "start runsvdir"
    set["runit"]["stop"] = "stop runsvdir"
    set["runit"]["reload"] = "reload runsvdir"
  end
when "gentoo"
  set["runit"]["sv_bin"] = "/usr/bin/sv"
  set["runit"]["chpst_bin"] = "/usr/bin/chpst"
  set["runit"]["service_dir"] = "/etc/service"
  set["runit"]["sv_dir"] = "/var/service"
  set["runit"]["executable"] = "/sbin/runit"
  set["runit"]["start"] = "/etc/init.d/runit-start start"
  set["runit"]["stop"] = "/etc/init.d/runit-start stop"
  set["runit"]["reload"] = "/etc/init.d/runit-start reload"
when "rhel"
  set["runit"]["sv_bin"] = "/usr/bin/sv"
  set["runit"]["chpst_bin"] = "/usr/bin/chpst"
  set["runit"]["service_dir"] = "/etc/service"
  set["runit"]["sv_dir"] = "/var/service"
  set["runit"]["executable"] = "/sbin/runit"
  if platform_version.to_i < 6
    set["runit"]["start"] = "/etc/init.d/runit-start start"
    set["runit"]["stop"] = "/etc/init.d/runit-start stop"
    set["runit"]["reload"] = "/etc/init.d/runit-start reload"
  else
    set["runit"]["start"] = "/etc/init.d/runit-start start"
    set["runit"]["stop"] = "/etc/init.d/runit-start stop"
    set["runit"]["reload"] = "/etc/init.d/runit-start reload"
  end
end

