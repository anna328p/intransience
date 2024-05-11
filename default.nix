{ lib, config, ... }:

let
    fileAttrsToMode = cfg: let
        rwxToChar = a: builtins.toString (
              (if a.read    then 4 else 0)
            + (if a.write   then 2 else 0)
            + (if a.execute then 1 else 0));

        cfgAll = cfg.all or {};

        sticky = if cfg.sticky then "1" else "0";
        owner = rwxToChar (cfg.owner // cfgAll);
        group = rwxToChar (cfg.group // cfgAll);
        other = rwxToChar (cfg.other // cfgAll);
    in
        "${sticky}${owner}${group}${other}";

    modeRE = "([01]?)([0-7])([0-7])([0-7])";

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
in {
    options.intransience = let
        inherit (lib)
            mkOption
            mkEnableOption
            mkDefault
            ;

        t = lib.types;

        tFileMode = let
            tModeString = t.strMatching modeRE;

            tModeAttrs = let
                rwxOption = mkOption {
                    type = t.submodule {
                        options = {
                            read = mkOption { type = t.bool; default = false; };
                            write = mkOption { type = t.bool; default = false; };
                            execute = mkOption { type = t.bool; default = false; };
                        };
                    };
                    default = { };
                };
            in t.submodule ({ config, ...}: {
                options = {
                    sticky = mkOption { type = t.bool; };
                    all = rwxOption;
                    owner = rwxOption;
                    group = rwxOption;
                    other = rwxOption;
                };

                config = let
                    defaults = {
                        read = mkDefault config.all.read;
                        write = mkDefault config.all.write;
                        execute = mkDefault config.all.execute;
                    };
                in {
                    owner = defaults;
                    group = defaults;
                    other = defaults;
                };
            });
        in
            t.either tModeAttrs tModeString;

        tPathOr = other: let
            convert = path: { inherit path; };
        in
            t.coercedTo t.str convert other;

    in {
        enable = mkEnableOption "the intransience module";

        datastores = mkOption {
            description = "TODO";

            type = t.attrsOf (t.submodule ({ name, config, ... }: let
                pathOption = mkOption {
                    description = ''
                        The entry's location, relative to the datastore's
                        base path.
                    '';
                    type = t.str;
                };

                methodOption = mkOption {
                    description = ''
                        The method by which this entry should be interpolated
                        into the filesystem.
                    '';

                    type = t.enum [ "bind" "symlink" ];
                    default = "bind";
                };

                permissionOpts = {
                    user
                  , group
                  , mode
                  , ...
                }@args: {
                    user = mkOption {
                        description = ''
                            The user that will own this entry in the datastore
                            and filesystem.
                        '';

                        type = t.str;
                        default = args.user;
                    };

                    group = mkOption {
                        description = ''
                            The group that will own this entry in the datastore
                            and filesystem.
                        '';

                        type = t.str;
                        default = args.group;
                    };

                    mode = mkOption {
                        description = ''
                            The default mode that this entry should have in the
                            datastore, if it doesn't already exist there.
                        '';

                        type = tFileMode;
                        default = args.mode;
                    };
                };

                kindOption = mkOption {
                    internal = true;
                    type = t.uniq (t.enum [ "file" "dir" ]);
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

                tEntryMod = {
                    basePath
                  , kind
                  , ...
                }@args: let
                    dscfg = config;
                in t.submodule ({ config, ... }: {
                    options = {
                        path = pathOption;
                        method = methodOption;

                        parentDirectory = let
                        	args' = args // { mode = addExecute args.mode; };
                        in
                        	if kind == "file"
                        		then permissionOpts args'
                        		else permissionOpts args;

                        basePath = mkOption {
                            description = ''
                                The base path under which this entry is found.
                            '';

                            internal = true;
                            type = t.path;
                            default = basePath;
                        };

                        fullPath = internalPathOption;
                        sourcePath = internalPathOption;

                        hideMount = mkOption {
                            type = t.bool;
                            default = dscfg.hideBindMounts;
                        };

                        kind = kindOption;
                    } // (permissionOpts args);

                    config = {
                        inherit kind;

                        fullPath = builtins.toString
                            (/. + (config.basePath + "/" + config.path));

                        sourcePath = builtins.toString
                            (/. + (dscfg.path + "/" + config.fullPath));
                    };
                });

                mkEntriesOption = args: mkOption {
                    type = t.listOf (tPathOr (tEntryMod args));
                    default = [ ];
                };

                internalEntryListOption = mkOption {
                    internal = true;
                    type = t.uniq (t.listOf (t.attrsOf t.anything));
                };

                internalPathOption = mkOption {
                    internal = true;
                    type = t.uniq t.path;
                };

            in {
                options = {
                    enable = mkEnableOption "this datastore";

                    path = mkOption {
                        description = ''
                            The root path of this datastore, where intransient
                            files are placed.
                        '';
                        
                        type = t.nullOr t.path;
                        default = name;
                    };

                    hideBindMounts = mkOption {
                        description = ''
                            Whether to prevent bind-mounts for this datastore
                            from showing up in lists of mounted drives.
                        '';

                        type = t.bool;
                        default = true;
                    };

                    etc = let
                        dscfg = config;

                        inherit (builtins) toString;

                        commonOpts = {
                            kind
                          , ...
                        }@args: t.submodule ({ config, ... }: {
                            options = {
                                path = pathOption;

                                kind = kindOption;

                                fullPath = internalPathOption;
                                sourcePath = internalPathOption;
                            } // (permissionOpts args);

                            config = {
                                inherit kind;

                                fullPath = toString
                                    (/etc + ("/" + config.path));

                                sourcePath = toString
                                    (/. + (dscfg.path + "/" + config.fullPath));
                            };
                        });
                    in {
                        files = mkOption {
                            type = t.listOf (tPathOr (commonOpts {
                                kind = "file";
                                user = "root";
                                group = "root";
                                mode = "0644";
                            }));

                            default = [ ];
                        };

                        dirs = mkOption {
                            type = t.listOf (tPathOr (commonOpts {
                                kind = "dir";
                                user = "root";
                                group = "root";
                                mode = "0755";
                            }));

                            default = [ ];
                        };

                        allEntries = internalEntryListOption;
                    };

                    byPath = mkOption {
                        type = t.attrsOf (t.submodule ({ name, config, ... }: {
                            options = {
                                files = mkEntriesOption {
                                    kind = "file";
                                    basePath = name;
                                    user = "root";
                                    group = "root";
                                    mode = "0644";
                                };

                                dirs = mkEntriesOption {
                                    kind = "dir";
                                    basePath = name;
                                    user = "root";
                                    group = "root";
                                    mode = "0755";
                                };
                            };
                        }));
                    };

                    files = mkEntriesOption {
                        kind = "file";
                        basePath = "/";
                        user = "root";
                        group = "root";
                        mode = "0644";
                    };

                    dirs = mkEntriesOption {
                        kind = "dir";
                        basePath = "/";
                        user = "root";
                        group = "root";
                        mode = "0755";
                    };

                    users = mkOption {
                        type = t.attrsOf (t.submodule ({ name, config, ... }: {
                            options = {
                                homePath = mkOption {
                                    type = t.path;
                                    default = "/home/${name}";
                                };

                                defaultUser = mkOption {
                                    type = t.str;
                                    default = name;
                                };

                                defaultGroup = mkOption {
                                    type = t.str;
                                    default = "users";
                                };

                                files = mkEntriesOption {
                                    kind = "file";
                                    basePath = config.homePath;
                                    user = config.defaultUser;
                                    group = config.defaultGroup;
                                    mode = "0644";
                                };

                                dirs = mkEntriesOption {
                                    kind = "dir";
                                    basePath = config.homePath;
                                    user = config.defaultUser;
                                    group = config.defaultGroup;
                                    mode = "0755";
                                };
                            };
                        }));
                        
                        default = { };
                    };

                    allFiles = internalEntryListOption;
                    allDirs = internalEntryListOption;
                    allEntries = internalEntryListOption;
                };

                config = let
                    inherit (builtins)
                        concatLists
                        concatMap
                        catAttrs
                        attrValues
                        ;

                    collect = attr: roots: let
                        trees = concatMap attrValues roots;
                    in
                        concatLists (catAttrs attr trees);

                    roots = [ config.byPath config.users ];
                in {
                    byPath."/" = { inherit (config) files dirs; };

                    allFiles = collect "files" roots;
                    allDirs = collect "dirs" roots;
                    allEntries = config.allFiles ++ config.allDirs;

                    etc.allEntries = config.etc.files ++ config.etc.dirs;
                };
            }));
        };
    };

    config = let
        inherit (builtins)
            isString
            filter
            attrValues
            listToAttrs
            catAttrs
            concatLists
            concatMap
            dirOf
            ;

        inherit (lib)
            mkIf
            mapAttrs'
            flip
            optional
            ;

        cfg = config.intransience;

        entryToBindMount = entry: {
            mountPoint = entry.fullPath;
            device = entry.sourcePath;

            options = [ "bind" "X-fstrim.notrim" ]
                ++ optional entry.hideMount "x-gvfs-hide";
        };

        allBindMounts = let
            entries = concatLists
                (catAttrs "allEntries"
                    (attrValues cfg.datastores));

            bindEntries = filter (e: e.method == "bind") entries;
        in
            listToAttrs (flip map bindEntries (entry: {
                name = entry.fullPath;
                value = entryToBindMount entry;
            }));

    in mkIf cfg.enable {
        fileSystems = allBindMounts;
        virtualisation.fileSystems = allBindMounts;

        systemd.tmpfiles.settings = let
            normalizeMode = mode:
                if isString mode
                    then mode
                    else fileAttrsToMode mode;

            mkBindEntry = target: type: entry: {
                name = target;
                value.${type} = {
                    inherit (entry) user group;
                    mode = normalizeMode entry.mode;
                };
            };

            mkLinkEntry = entry: {
                name = entry.fullPath;
                value."L+" = {
                    inherit (entry) user group;
                    argument = entry.sourcePath;
                };
            };

            filterEntries = method: ds:
                filter (e: e.method == method) ds.allEntries;

            mkBindTargets = name: ds: let
                bindEntries = filterEntries "bind" ds;
            in {
                name = "12-intransience-binds-${name}";
                value = listToAttrs (flip concatMap bindEntries (entry: let
                    parentPath = dirOf entry.fullPath;

                    parentDir = if parentPath != entry.basePath
                        then [ { 
                            name = parentPath;
                            value."d" = {
                                inherit (entry.parentDirectory) user group;
                                mode = normalizeMode entry.parentDirectory.mode;
                            };
                        } ]
                        else [ ];
                in
                    if entry.kind == "file" then
                        [
                            (mkBindEntry entry.fullPath "f" entry)
                            (mkBindEntry entry.sourcePath "f" entry)
                        ] ++ parentDir
                    else if entry.kind == "dir" then
                        [
                            (mkBindEntry entry.fullPath "d" entry)
                            (mkBindEntry entry.sourcePath "d" entry)
                        ] ++ parentDir
                    else
                        throw "unreachable"
                ));
            };

            mkLinkTargets = name: ds: let
                linkEntries = filterEntries "symlink" ds;
            in
                {
                    name = "13-intransience-links-${name}";
                    value = listToAttrs (flip map linkEntries mkLinkEntry);
                };

            mkEtcTargets = name: ds: let
                etcEntries = ds.etc.allEntries;
            in
               {
                   name = "14-intransience-etc-${name}";
                   value = listToAttrs (flip map etcEntries (entry:
                       if entry.kind == "file" then
                           mkBindEntry entry.sourcePath "f" entry
                       else if entry.kind == "dir" then
                           mkBindEntry entry.sourcePath "d" entry
                       else
                           throw "unreachable"
                   ));
               };
                

            forAllStores = flip mapAttrs' cfg.datastores;
        in
            {}  // (forAllStores mkBindTargets)
                // (forAllStores mkLinkTargets)
                # // (forAllStores mkEtcTargets)
                ;

        environment.etc = let
            allEtc = concatMap
                    (v: v.etc.allEntries)
                    (attrValues cfg.datastores);

        in listToAttrs (flip map allEtc (entry: {
            name = entry.path;
            value = {
                source = entry.sourcePath;
                mode = "symlink";
            };
        }));
    };
}
