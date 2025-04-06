{ prelude, lib, ... }:

prelude.mkLibrary {
	inherit
		prelude
		lib
		;
} ({ using, ... }:
	using {
		modes      = ./modes.nix;

		opts       = ./options/options.nix;
		submodules = ./options/submodules.nix;
		util       = ./options/util.nix;
		desc       = ./options/descriptions.nix;
		
		impl       = ./impl/default.nix;
		tmpfiles   = ./impl/tmpfiles.nix;
		bindMounts = ./impl/bind-mounts.nix;
		etc        = ./impl/etc.nix;
	} (_: {})
)
