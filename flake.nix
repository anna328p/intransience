{
	description = "Intransience";

	inputs = {
		nix-prelude.url = "github:anna328p/nix-prelude";

		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		systems.url = "github:nix-systems/default";
	};

	outputs = { nixpkgs, systems, nix-prelude, ... }:
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
				docs = pkgs.callPackage ./generate-docs.nix { inherit localLib; };
			});

			nixosModules = rec {
				intransience = import ./module.nix { inherit localLib; };
				default = intransience;
			};

			lib = localLib;
		};
}
