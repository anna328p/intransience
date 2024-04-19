{
	description = "Intransience";

	outputs = { ... }: {
		nixosModules = rec {
			intransience = ./default.nix;
			default = intransience;
		};
	};
}
