{ self, lib, ... }:

let
	inherit (self)
		desc
		submodules

		tFileMode
		addExecute
		;

	inherit (lib)
		mkOption
		literalExpression
		;

	t = lib.types;
in rec {
	exports = self: { inherit (self)
		topLevel
		;
	};

	/**
	  tPathOr : OptionType -> OptionType
	 */
	tPathOr = other: let
		convert = path: { inherit path; };
	in
		t.coercedTo t.str convert other;


	##
	# permissions :
	#     Record { user : String, group : String, mode : FileMode }
	#         -> Dict ModuleOption
	mkPermissions = {
		user
	  , group
	  , mode
	  , ...
	}@args: {
		user = mkOption {
			type = t.str;
			default = args.user;
			description = desc.perms.user;
		};

		group = mkOption {
			type = t.str;
			default = args.group;
			description = desc.perms.group;
		};

		mode = mkOption {
			type = tFileMode;
			default = args.mode;
			description = desc.perms.mode;
		};
	};

	###
	# Entry

	entry = {
		##
		# path : ModuleOption
		path = mkOption {
			type = t.str;
			example = "/var/lib/foo";
			description = desc.entry.path;
		};

		##
		# method : ModuleOption
		method = mkOption {
			type = t.enum [ "bind" "symlink" ];
			default = "bind";
			description = desc.entry.method;
		};

		##
		# kind : ModuleOption
		kind = mkOption {
			internal = true;
			type = t.uniq (t.enum [ "file" "dir" ]);
			description = desc.entry.kind;
		};

		##
		# hideMount : ModuleOption
		hideMount = mkOption {
			type = t.bool;
			defaultText = literalExpression "datastore.hideBindMounts";
			description = desc.entry.hideMount;
		};

		##
		# parentDirectory.build : Enum [ "file" "dir" ] -> Dict ModuleOption
		parentDirectory.build = kind: args: let
			args' = if kind == "file"
				then args // { mode = addExecute args.mode; }
				else args;
		in
			mkPermissions args';
	};

	###
	# Internal

	internal = {
		##
		# entryList : ModuleOption
		entryList = mkOption {
			type = t.uniq (t.listOf (t.attrsOf t.anything));
			internal = true;
		};

		##
		# path : ModuleOption
		path = mkOption {
			type = t.uniq t.path;
			internal = true;
		};

		##
		# basePath : ModuleOption
		basePath = mkOption {
			type = t.uniq t.path;
			defaultText = "args.basePath";

			internal = true;

			description = desc.entry.basePath;
		};
	};

	###
	# Datastore
	ds = {
		##
		# entries' : (Dict Any -> ModuleOption) -> Dict Any -> ModuleOption
		entries'.build = fn: args: mkOption {
			type = t.listOf (tPathOr (fn args));
			default = [ ];
			example = [ "/foo/bar" { path = "/foo/baz"; mode = "0600"; } ];
			description = desc.ds.entryList;
		};

		##
		# entries : Dict Any -> ModuleOption
		entries.build = ds.entries'.build submodules.entry.build;

		##
		# etcEntries : Dict Any -> ModuleOption
		etcEntries.build = ds.entries'.build submodules.etcEntry.build;

		##
		# path : string -> ModuleOption
		path.build = name: mkOption {
			type = t.nullOr t.path;
			default = name;
			description = desc.ds.path;
		};

		##
		# hideBindMounts : ModuleOption
		hideBindMounts = mkOption {
			type = t.bool;
			default = true;
			description = desc.ds.hideBindMounts;
		};

		etc.build = defaults: mkOption {
			type = submodules.ds.etc.build defaults;
			description = desc.ds.etc;
			default = { };
		};

		byPath.build = defaults: mkOption {
			type = t.attrsOf (submodules.ds.byPath.build defaults);
			description = desc.ds.byPath;
			default = { };
		};
		
		users.build = defaults: mkOption {
			type = t.attrsOf (submodules.ds.users.build defaults);
			description = desc.users.topLevel;
			default = { };
		};
	};

	###
	# Users
	users = {
		##
		# homePath.build : String -> ModuleOption
		homePath.build = name: mkOption {
			type = t.path;
			default = "/home/${name}";
			description = desc.users.homePath;
		};

		##
		# defaultUser.build : String -> ModuleOption
		defaultUser.build = name: mkOption {
			type = t.str;
			default = name;
			description = desc.users.defaultUser;
		};

		##
		# defaultGroup : ModuleOption
		defaultGroup = mkOption {
			type = t.str;
			default = "users";
			description = desc.users.defaultGroup;
		};
	};

	##
	# topLevel : ModuleOption
	topLevel = mkOption {
		type = submodules.topLevel;
		description = desc.topLevel;
		default = { enable = false; };
	};
}
