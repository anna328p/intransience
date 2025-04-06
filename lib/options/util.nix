{ ... }:

{
	exports = self: { inherit (self)
		mkEntryDefaults
		;
	};

	##
	# mkEntryDefaults : Record { hideBindMounts : Bool, ... } -> Dict Any
	mkEntryDefaults = config: let
		base = {
			dsRootPath = config.path;
		};
	in {
		file = base // {
			kind = "file";
			mode = "0644";
		};

		dir = base // {
			kind = "dir";
			mode = "0755";
		};

		root = {
			user = "root";
			group = "root";
		};

		atPath = basePath: {
			inherit basePath;
			inherit (config) hideBindMounts;
		};

		forUser = userCfg: {
			basePath = userCfg.homePath;
			user = userCfg.defaultUser;
			group = userCfg.defaultGroup;
			inherit (config) hideBindMounts;
		};
	};
}
