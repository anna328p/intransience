{ lib, ... }:

# Mode options
let
	inherit (builtins)
		isString
		toString
		;

	inherit (lib)
		mkOption
		mkDefault
		;

	t = lib.types;
in rec {
	exports = self: { inherit (self)
		tFileMode
		fileAttrsToMode
		modeToFileAttrs
		addExecute
		normalizeMode
		;
	};

	##
	# Regex that matches octal mode strings.
    modeRE = "([01]?)([0-7])([0-7])([0-7])";


	##
	# ModeString : StrMatching modeRE
	tModeString = t.strMatching modeRE;


	##
	# PermissionField = Record {
	#     read    : Bool,
	#     write   : Bool,
	#     execute : Bool
	# }

	mkBitOption = desc: mkOption {
		type = t.bool;
		default = false;
		description = "Whether the given class can ${desc}.";
	};

	rwxOption = mkOption {
		type = t.submodule {
			options = {
				read    = mkBitOption "read file contents or directory entry names";
				write   = mkBitOption "modify file contents or directory entries";
				execute = mkBitOption "execute the file or access directory entries";
			};
		};
		default = { };
	};

	##
	# ModeAttrs = Record {
	#     sticky : Bool,
	#     owner  : PermissionField,
	#     group  : PermissionField,
	#     other  : PermissionField,
	#     all    : PermissionField
	# }

	tModeAttrs = t.submodule ({ config, ...}: {
		options = {
			sticky = mkOption { type = t.bool; };
			all = rwxOption;
			owner = rwxOption;
			group = rwxOption;
			other = rwxOption;
		};

		config = let
			defaults = {
				read    = mkDefault config.all.read;
				write   = mkDefault config.all.write;
				execute = mkDefault config.all.execute;
			};
		in {
			owner = defaults;
			group = defaults;
			other = defaults;
		};
	});


	##
	# FileMode : Either ModeAttrs ModeString

	tFileMode = t.either tModeAttrs tModeString;


	##
	# Turns an attrset into an octal mode string.
    fileAttrsToMode = cfg: let
        rwxToChar = a: toString (
              (if a.read    then 4 else 0)
            + (if a.write   then 2 else 0)
            + (if a.execute then 1 else 0));

        cfgAll = cfg.all or {};
        toChar = v: rwxToChar (cfgAll // v);

        sticky = if cfg.sticky then "1" else "0";
        owner = toChar cfg.owner;
        group = toChar cfg.group;
        other = toChar cfg.other;
    in
        "${sticky}${owner}${group}${other}";


	##
	# Turns an octal mode string into an attrset.
    modeToFileAttrs = str: let
		inherit (builtins) match elemAt map fromJSON;

		numToAttrs = n: let
			bitR = n / 4;
			bitW = n / 2 - (bitR * 2);
			bitX = n     - (bitR * 4) - (bitW * 2);
		in {
			read    = bitR == 1;
			write   = bitW == 1;
			execute = bitX == 1;
		};

    	modeParts = match modeRE str;
    	modeInts = map fromJSON modeParts;
    	part = elemAt modeInts;
    in 
    	assert modeParts != null;
		{
			sticky = (part 0) == 1;
			all = {};
			owner = numToAttrs (part 1);
			group = numToAttrs (part 2);
			other = numToAttrs (part 3);
		};

	addExecute = mode: let
		attrs = modeToFileAttrs mode;

		overrideExec = set:
			if set.read
				then set // { execute = true; }
			else set;
	in
		fileAttrsToMode {
			inherit (attrs) sticky;
			owner = overrideExec attrs.owner;
			group = overrideExec attrs.group;
			other = overrideExec attrs.other;
		};


	##
	# normalizeMode : Either String FileMode -> String
	normalizeMode = mode:
		if isString mode
			then mode
			else fileAttrsToMode mode;
}
