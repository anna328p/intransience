{
	description = "Intransience";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		systems.url = "github:nix-systems/default";
	};

	outputs = { nixpkgs, systems, ... }:
		let
			eachSystem = nixpkgs.lib.genAttrs (import systems);
		in {
			packages = eachSystem (system: let
				pkgs = nixpkgs.legacyPackages.${system};
			in {
				docs = pkgs.callPackage ./generate-docs.nix { };
			});

			nixosModules = rec {
				intransience = ./default.nix;
				default = intransience;
			};
		};
}
