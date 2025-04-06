{
	description = "Intransience";

	inputs = {
		nix-prelude.url = "github:anna328p/nix-prelude";

		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		systems.url = "github:nix-systems/default";
	};

	outputs = { self, nixpkgs, systems, nix-prelude, ... }@flakes:
		let
			eachSystem = nixpkgs.lib.genAttrs (import systems);

			prelude = nix-prelude.lib;

			localLib = import ./lib {
				inherit (nixpkgs) lib;
				inherit prelude;
			};

		in {
			packages = eachSystem (system: let
				pkgs = nixpkgs.legacyPackages.${system};
			in {
				docs = pkgs.callPackage ./generate-docs.nix { inherit flakes; };
			});

			checks = eachSystem (system: let
				pkgs = nixpkgs.legacyPackages.${system};
			in {
				simple = pkgs.callPackage ./test/simple.nix { inherit flakes; };
			});

			nixosModules = rec {
				intransience = import ./module.nix { inherit localLib; };
				default = intransience;
			};

			lib = localLib;
		};
}
