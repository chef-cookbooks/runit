Description
===========

Installs runit and provides the `runit_service` LWRP for managing new
services under runit.

This cookbook does not use runit to replace system init, nor are there
plans to do so.

For more information about runit:

* http://smarden.org/runit/

Requirements
============

## Platform:

* Debian/Ubuntu
* Gentoo
* RHEL

Attributes
==========

See `attributes/default.rb` for defaults.

* `node['runit']['sv_bin']` - Full path to the `sv` binary.
* `node['runit']['chpst_bin']` - Full path to the `chpst` binary.
* `node['runit']['service_dir']` - Full path to the default "services"
  directory where enabled services are linked.
* `node['runit']['sv_dir']` - Full path to the directory where the
  service lives, which gets linked to `service_dir`.

Recipes
=======

default
-------

Installs and sets up runit on the system. Assumes a package
installation, so native package must exist. This recipe will make sure
that the runsvdir process gets started, ensures that inittab is
updated with the SV entry. The package will be preseeded on
ubuntu/debian signal init, otherwise the appropriate action is chosen
to notify the runsvdir command.

Older versions of Ubuntu (<= 10.04) are supported, but support may be
removed in a future version.

Resource/Provider
=================

This cookbook includes an LWRP for managing runit services.

Actions:

- *start* - starts the service
- *stop* - stops the service
- *enable* - enables the service, creating the run scripts and symlinks
- *disable* - downs the service and removes the service symlink
- *restart* - restarts the service
- *reload* - reloads the service with force-reload
- *once* - starts the service once
- *hup* - sends the hup signal to the service
- *cont* - sends the cont signal to the service
- *term* - sends the term signal to the service
- *kill* - sends the kill signal to the service

Service management actions are taken with runit's "sv" program.

Parameter Attributes

- *service_name* - name of the service - name attribute
- *directory* - directory where the service configuration lives
- *control* - customize control of the service, see runsv man page
- *options* - options passed as variables to templates, for
   compatibility with legacy runit service definition
- *variables* - uses the options hash to pass variables to templates
- *env* - environment values to pass via the service's env directory
- *log* - whether to start the service's logger with svlogd, requires
   a template `sv-service_name-log-run.erb` to configure the logs run
   script
- *cookbook* - cookbook where templates should be located instead of
   where the LWRP is used
- *template* - name of the template, defaults to `service_name`, set
   to false to not render a template (e.g. if a package supplies its
   own runit scripts)
- *finish* - whether the service has a finish script, requires a
   template `sv-service_name-finish.erb`
- *owner* - user that should own the templates created to enable the
   service
- *group* - group that should own the templates created to enable the
   service

runsv(8) man page is available online:

* http://smarden.org/runit/runsv.8.html

svlogd(8) man page is available online:

* http://smarden.org/runit/svlogd.8.html

Definitions
===========

The definition in this cookbook is deprecated by the LWRP described
above. It is kept for compatibility and will be removed by version 1.0
of this cookbook. Not all the features of the definition will be
ported to the LWRP.

runit\_svc
----------

This definition includes `recipe[runit]` to ensure it is installed
first. As LWRPs cannot use `include_recipe`, this will not be
available in future versions, so runit will need to be in a role or
node run list.

Sets up a new service to be managed and supervised by runit. It will
be created in the `node['runit']['sv_dir']` unless otherwise specified
in the `directory` parameter (see below).

### Parameters:

* `name` - Name of the service. This will be used in the template file
  names (see __Usage__), as well as the name of the service resource
  created in the definition.
* `directory` - the directory where the service's configuration and
  scripts should be located. Default is `node['runit']['sv_dir']`.
* `only_if` - unused, will be removed in a future version (won't be
  present in lwrp). Default is false.
* `finish_script` - if true, a finish script should be created.
  Default is false. For more information see: [Description of runsv](http://smarden.org/runit/runsv.8.html).
* `control` - Array of signals to create a control directory with
  control scripts (e.g., `sv-SERVICE-control-SIGNAL.erb`, where
  SERVICE is the name parameter for the service name, and SIGNAL is
  the Unix signal to send. Default is an empty array. For more
  information see:
  [Customize Control](http://smarden.org/runit/runsv.8.html)
* `run_restart` - if true, the service resource will subscribe to
  changes to the run script and restart itself when it is modified.
  Default is true.
* `active_directory` - used for user-specific services. Default is
  `node['runit']['service_dir']`.
* `owner` - userid of the owner for the service's files, and should be
  used in the run template with chpst to ensure the service runs as
  that user. Default is root.
* `group` - groupid of the group for the service's files, and should
  be used in the run template with chpst to ensure the service runs as
  that group. Default is root.
* `template_name` - specify an alternate name for the templates
  instead of basing them on the name parameter. Default is the name parameter.
* `log_template_name` - specify an alternate name for the runit log template
  instead of basing them on the template_name parameter. Default is the
  template_name parameter.
* `control_template_names` - specify alternate names for runit control signal
  templates instead of basing them on the template_name parameter. Default
  is the template_name parameter.
* `finish_script_template_name` - specify an altername for the finish script
  template. Default is the template_name parameter
* `start_command` - The command used to start the service in
  conjunction with the `sv` command and the `service_dir` name.
  Default is `start`.
* `stop_command` - The command used to stop the service in conjunction
  with the `sv` command and the `service_dir` name. Default is `stop`.
* `restart_command` - The command used to restart the service in
  conjunction with the `sv` command and the `service_dir` name.  You
  may need to modify this to send an alternate signal to restart the
  service depending on the nature of the process. Default is `restart`
* `status_command` - The command used to check status for the service in
  conjunction with the `sv` command and the `service_dir` name. This
  is used by chef when checking the current resource state in managing
  the service. Default is `status`.
* `options` - a Hash of variables to pass into the run and log/run
  templates with the template resource `variables` parameter.
  Available inside the template(s) as `@options`. Default is an empty Hash.
* `env` - a Hash of environment variables to write out in the
  service's `env` directory.
* `control_user` - a non-privileged user that can control the service
* `default_logger` - sets up a default `log/run` script with svlogd
  logging to `./main`.
* `nolog` - if true, the log directory and logger script isn't set up,
  defaults to false.

### Examples:

Create templates for `sv-myservice-run.erb` and
`sv-myservice-log-run.erb` that have the commands for starting
myservice and its logger.

    runit_svc "myservice"

See __Usage__ for expanded examples.

Usage
=====

To get runit installed on supported platforms, use `recipe[runit]`.
Once it is installed, use the `runit_service` definition to set up
services to be managed by runit. Do note that once
[CHEF-154](http://tickets.opscode.com/browse/CHEF-154) is implemented,
some of the usage/implementation here will change. In order to use the
`runit_service` definition, two templates must be created for the
service, `cookbook_name/templates/default/sv-SERVICE-run.erb` and
`cookbook_name/templates/default/sv-SERVICE-log-run.erb`. Replace
`SERVICE` with the name of the service you're managing. For more usage,
see __Examples__.

Examples
--------

We'll set up `chef-client` to run as a service under runit, such as is
done in the `chef-client` cookbook. This example will be more simple
than in that cookbook. First, create the required run template,
`chef-client/templates/default/sv-chef-client-run.erb`.

    #!/bin/sh
    exec 2>&1
    exec /usr/bin/env chef-client -i 1800 -s 30

Then create the required log/run template,
`chef-client/templates/default/sv-chef-client-log-run.erb`.

    #!/bin/sh
    exec svlogd -tt ./main

__Note__ This will cause output of the running process to go to
`/etc/sv/chef-client/log/main/current`.

Finally, set up the service in the `chef-client` recipe with:

    runit_service "chef-client"

Next, let's set up memcached with some additional options. First, the
`memcached/templates/default/sv-memcached-run.erb` template:

    #!/bin/sh
    exec 2>&1
    exec chpst -u <%= @options[:user] %> /usr/bin/memcached -v -m <%= @options[:memory] %> -p <%= @options[:port] %>

Note that the script uses chpst (which comes with runit) to set the
user option, then starts memcached on the specified memory and port
(see below).

The log/run template,
`memcached/templates/default/sv-memcached-log-run.erb`:

    #!/bin/sh
    exec svlogd -tt ./main

Finally, the `runit_service` in our recipe:

    runit_service "memcached" do
      options({
        :memory => node[:memcached][:memory],
        :port => node[:memcached][:port],
        :user => node[:memcached][:user]}.merge(params)
      )
    end

This is where the user, port and memory options used in the run
template are used.

License and Author
==================

Author:: Adam Jacob <adam@opscode.com>
Author:: Joshua Timberman <joshua@opscode.com>

Copyright:: 2008-2011, Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
