{ prelude, self, lib, ... }:

let
	inherit (builtins)
		filter
		listToAttrs
		concatMap
		dirOf
		;

	inherit (prelude)
		optional
		flip
		;

	inherit (self)
		mapToAttrs
		normalizeMode
		;

	inherit (lib)
		mapAttrs'
		;
in rec {
	exports = self: { inherit (self)
		collectTmpfiles
		;
	};

	##
	# filterEntries : String -> Datastore -> Entry
	filterEntries = method: ds:
		filter (e: e.method == method) ds.allEntries;

	##
	# mkBindEntry : String -> String -> Entry -> Mapping Dict
	mkBindEntry = target: type: entry:
		{
			name = target;
			value.${type} = {
				inherit (entry) user group;
				mode = normalizeMode entry.mode;
			};
		};

	##
	# mkBindTargets : String -> Datastore -> Mapping Dict
	mkBindTargets = name: ds: let
		##
		# mkTarget : Entry -> [Mapping Dict]
		mkTarget = entry: let
			##
			# parentPath : String
			parentPath = dirOf entry.fullPath;

			##
			# parentDirEntry : [Mapping Dict]
			parentDirEntry = optional (parentPath != entry.basePath)
				(mkBindEntry parentPath "d" entry.parentDirectory);

			##
			# action : String
			action = if entry.kind == "file" then "f"
				else if entry.kind == "dir"  then "d"
				else throw "unreachable";
		in
			[
				(mkBindEntry entry.fullPath   action entry)
				(mkBindEntry entry.sourcePath action entry)
			] ++ parentDirEntry;

		##
		# bindEntries : [Entry]
		bindEntries = filterEntries "bind" ds;

	in {
		name = "12-intransience-binds-${name}";
		value = listToAttrs (concatMap mkTarget bindEntries);
	};

	##
	# mkLinkEntry : Dict -> Mapping Dict
	mkLinkEntry = entry:
		{
			name = entry.fullPath;
			value."L+" = {
				inherit (entry) user group;
				argument = entry.sourcePath;
			};
		};

	##
	# mkLinkTargets : String -> Datastore -> Mapping Dict
	mkLinkTargets = name: ds: let
		linkEntries = filterEntries "symlink" ds;
	in
		{
			name = "13-intransience-links-${name}";
			value = mapToAttrs mkLinkEntry linkEntries;
		};

	##
	# collectTmpfiles : [Datastore] -> Dict Any
	collectTmpfiles = datastores: let
		forAllStores = flip mapAttrs' datastores;
	in
		{}  // (forAllStores mkBindTargets)
			// (forAllStores mkLinkTargets)
			;
}
