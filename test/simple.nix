{ pkgs, flakes, ... }:

pkgs.testers.runNixOSTest ({ lib, ... }: {
    name = "simple";

    nodes.machine = { pkgs, ... }: {
        imports = [
            flakes.self.nixosModules.default
        ];

        intransience = {
            enable = true;

            datastores."/test" = {
                dirs = [
                    "/foo"
                ];
            };
        };
    };

    testScript = /* python */ ''
        from pathlib import Path

        if Path("/foo").exists() and Path("/test/foo").exists():
            machine.succeed("passed")
        else:
            machine.fail("expected /foo and /test/foo to exist, but they do not")
    '';
})

# vim: set et sw=4 ts=4:
