#!/usr/bin/env bats

@test "runit package has been installed" {
    dpkg --get-selections | grep runit
}

@test "runit named executable exist" {
    [ -x '/sbin/runit' ]
}

@test "runit runsvdir file should exist" {
    [ -f '/etc/event.d/runsvdir' ]
}

@test "runit runsvdir is running" {
    ps ax | grep '[r]unsvdir'
}

@test "runit service directory exists" {
    [ -d '/etc/sv' ]
}

# part of the runit package
@test "runit getty service file has been installed" {
    [ -x '/etc/sv/getty-5/run' ]
}
