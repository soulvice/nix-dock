

set shell := [ "bash" ]

default:
    @just --list

switch host:
    nixos-rebuild switch --flake .#{{host}}

[group('nix')]
shell:
    nix develop .#default

[linux]
[group('services')]
list-inactive:
    systemctl list-units -all --state=inactive

[linux]
[group('services')]
list-failed:
    systemctl list-units -all --state=failed

[linux]
[group('services')]
list-systemd:
    systemctl list-units systemd-*

[linux]
[group('docker')]
d-stats:
    docker stats

[linux]
[group('docker')]
d-cd:
    cd /docker