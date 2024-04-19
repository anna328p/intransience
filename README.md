# intransience

A NixOS module inspired by [impermanence].

Documentation is lacking but will be improved later.

Instead of using a custom script, uses systemd-tmpfiles and defines mounts under `fileSystems`.

Defines a set of options to persist directories in `/etc` using `environment.etc`. Unlike `impermanence`, this is compatible with `/etc` overlay (`system.etc.overlay`).

Expects the root filesystem to be a tmpfs.

[impermanence]: https://github.com/nix-community/impermanence
