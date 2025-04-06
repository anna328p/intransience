{ self, lib, prelude, ... }:

let
	inherit (builtins)
		toString
		;

	inherit (lib)
		mkOption
		mkEnableOption
		mkDefault
		;

	inherit (self)
		opts
		desc

		mkEntryDefaults
		;

	t = lib.types;
in rec {
	exports = _: { };

	##
	# entry : Record -> OptionType
	entry.build = {
		basePath       # : Path
	  , kind           # : Enum [ "file" "dir" ]
	  , user           # : String
	  , group          # : String
	  , mode           # : ModeAttrs
	  , hideBindMounts # : Bool
	  , dsRootPath     # : Path
	}@args: let
		permissionArgs = { inherit user group mode; };

	in t.submodule ({ config, ... }: let
		fullPath   = toString (/. + (config.basePath + "/" + config.path));
		sourcePath = toString (/. + (args.dsRootPath + "/" + config.fullPath));
	in {
		##
		# Interface

		options = {
			inherit (opts.entry)
				path
				method
				hideMount;

			kind = opts.internal.kind.withDefault kind;
			
			basePath = opts.internal.basePath.withDefault basePath;

			inherit (opts.mkPermissions permissionArgs)
				user
				group
				mode;

			parentDirectory = opts.entry.parentDirectory.build kind permissionArgs;

			fullPath   = opts.internal.path.withDefault fullPath;
			sourcePath = opts.internal.path.withDefault sourcePath;
		};

		##
		# Implementation

		config = {
			hideMount = mkDefault args.hideBindMounts;
		};
	});


	etcEntry.build = {
		kind
	  , user
	  , group
	  , mode
	  , dsRootPath
	}: t.submodule ({ config, ... }: let
		fullPath   = toString (/etc + ("/" + config.path));
		sourcePath = toString (/.   + (dsRootPath + "/" + config.fullPath));
	in {
		##
		# Interface

		options = let
			permissionArgs = { inherit user group mode; };
		in {
			inherit (opts.entry)
				path;

			inherit (opts.mkPermissions permissionArgs)
				user
				group
				mode;

			kind = opts.internal.kind.withDefault kind;

			fullPath   = opts.internal.path.withDefault fullPath;
			sourcePath = opts.internal.path.withDefault sourcePath;
		};
	});

	ds.users.build = defaults: t.submodule ({ name, config, ... }: {
		options = let
			inherit (defaults) file dir forUser;
		in {
			# Meta

			homePath = opts.users.homePath.build name;

			defaultUser  = opts.users.defaultUser.build name;
			defaultGroup = opts.users.defaultGroup;

			# Entries

			files = opts.ds.entries.build (file // forUser config);
			dirs  = opts.ds.entries.build (dir  // forUser config);
		};
	});


	ds.etc.build = defaults: t.submodule ({ name, config, ... }: {
		options = let
			inherit (defaults) file dir root;
		in {
			files = opts.ds.etcEntries.build (file // root);
			dirs  = opts.ds.etcEntries.build (dir  // root);

			# Internal

			allEntries = opts.internal.entryList;
		};
	});


	ds.byPath.build = defaults: t.submodule ({ name, ... }: {
		options = let
			inherit (defaults) file dir atPath root;
		in {
			files = opts.ds.entries.build (file // (atPath name) // root);
			dirs  = opts.ds.entries.build (dir  // (atPath name) // root);
		};
	});


	##
	# datastore : OptionType
	datastore = t.submodule ({ name, config, ... }: let
		defaults = mkEntryDefaults config;

		inherit (defaults) file dir atPath root;
	in {
		##
		# Interface

		options = {
			# Meta

			enable = mkEnableOption "this datastore";

			path = opts.ds.path.build name;

			hideBindMounts = opts.ds.hideBindMounts;

			# Entries

			byPath = opts.ds.byPath.build defaults;

			users  = opts.ds.users.build defaults;

			files  = opts.ds.entries.build (file // atPath "/" // root);
			dirs   = opts.ds.entries.build (dir // atPath "/" // root);

			etc    = opts.ds.etc.build defaults;

			# Internal

			allFiles   = opts.internal.entryList;
			allDirs    = opts.internal.entryList;
			allEntries = opts.internal.entryList;
		};

		##
		# Implementation

		config = let
			collect = attr: roots: let
				inherit (builtins) concatLists concatMap catAttrs attrValues;

				trees = concatMap attrValues roots;
			in
				concatLists (catAttrs attr trees);

			roots = [ config.byPath config.users ];
		in {
			byPath."/" = { inherit (config) files dirs; };

			allFiles   = collect "files" roots;
			allDirs    = collect "dirs" roots;
			allEntries = config.allFiles ++ config.allDirs;

			etc.allEntries = config.etc.files ++ config.etc.dirs;
		};
	});

	topLevel = t.submodule {
		options = {
			enable = mkEnableOption "the intransience module";

			datastores = mkOption {
				description = desc.datastores;
				type = t.attrsOf datastore;
				default = {};
			};
		};
	};
}
