{ localLib }:

{ lib, config, ... }:

{
	##
	# Interface

    options.intransience = localLib.topLevel;

	##
	# Implementation

    config = let
        inherit (lib)
            mkIf
            ;

		inherit (localLib)
			collectBindMounts
			collectTmpfiles
			collectEtc
			;

        cfg = config.intransience;

    in mkIf cfg.enable rec {
        fileSystems = collectBindMounts cfg.datastores;
        virtualisation.fileSystems = fileSystems;

        systemd.tmpfiles.settings = collectTmpfiles cfg.datastores;

        environment.etc = collectEtc cfg.datastores;
    };
}
