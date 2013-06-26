#!/usr/bin/env bats

@test "runit memcached service file should exist" {
    [ -x '/etc/sv/memcached/run' ]
}

@test "runit supervised memcached should be running with options" {
    ps aux | grep '[m]emcached -v -m 42 -p 11211'
}
