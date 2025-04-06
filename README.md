# intransience

A NixOS module inspired by [impermanence].

Instead of using a custom script, uses systemd-tmpfiles and defines mounts under `fileSystems`.

Defines a set of options to persist directories in `/etc` using `environment.etc`. Unlike `impermanence`, this is compatible with `/etc` overlay (`system.etc.overlay`).

Expects the root filesystem to be a tmpfs.

## Option documentation

[Here.](https://anna328p.github.io/intransience/)

## Usage

[Real-world example here.](https://github.com/anna328p/configuration.nix/tree/main/common/impermanent)

### Simple example

Requires flakes.

`flake.nix`  
```nix
{
    description = "A flake";

    inputs = {
        intransience.url = "github:anna328p/intransience";
    };

    outputs = { nixpkgs, intransience, ... }: {
        nixosConfigurations."foo" = nixpkgs.lib.nixosSystem {
            modules = [
                intransience.nixosModules.default
                ./configuration.nix
                # ...
                ./persistence.nix
            ];
        };
    };
}
```

`persistence.nix`  
```nix
{
    intransience.enable = true;

    intransience.datastores."/mnt/persistent/safe" = {
        dirs = [
            "/srv"
            "/var/log"
        ];

        byPath."/var/lib".dirs = [
            "nixos"
            "systemd"
            "NetworkManager"
        ];

        etc.files = [
            "machine-id"
        ];
        
        users.anna = {
            dirs = [
                ".local/state"
                ".mozilla"

                "Documents"
                "Pictures"
            ];

            files = [
                ".local/share/zsh/zsh_history"
            ];
        };
    };

    intransience.datastores."/mnt/persistent/volatile" = {
        dirs = [
            "/var/cache"
        ];

        users.anna = {
            dirs = [
                ".cache"
            ];
        };
    };
}
```

[impermanence]: https://github.com/nix-community/impermanence
