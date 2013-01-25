## v1.0.0:

* [COOK-2254] - (formerly CHEF-154) Convert `runit_service` definition
  to a service resource named `runit_service`.

This is a backwards incompatible version. Changes of Note:

1. The "runit" recipe must be included before the runit_service resource
can be used.
2. runit_service definition created a "service" resource. This is now a
"runit_service" resource, for the purposes of notifications.
3. enable action blocks waiting for supervise/ok after the service symlink
is created.
4. Create user-controlled services per the runit documentation.
5. Some parameters in the definition have changed names in the resource.

The following parameters in the definition are renamed in the resource
to clarify their intent.

* directory -> sv_dir
* active_directory -> service_dir
* template_name -> use service_name (name attribute)
* nolog -> set "log" to false
* start_command -> unused (was previously in the "service" resource)
* stop_command -> unused (was previously in the "service" resource)
* restart_command -> unused (was previously in the "service" resource)

## v0.16.2:

* [COOK-1576] - Do not symlink /etc/init.d/servicename to /usr/bin/sv
  on debian
* [COOK-1960] - default_logger still looks for sv-service-log-run
  template
* [COOK-2035] - runit README change

## v0.16.0:

* [COOK-794] default logger and `no_log` for `runit_service`
  definition
* [COOK-1165] - restart functionality does not work right on Gentoo
  due to the wrong directory in the attributes
* [COOK-1440] - Delegate service control to normal user

## v0.15.0:

* [COOK-1008] - Added parameters for names of different templates in runit
