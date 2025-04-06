{ self, prelude, ... }:

let
	inherit (builtins)
		catAttrs
		concatLists
		attrValues
		filter
		;

	inherit (prelude)
		optional
		;

	inherit (self)
		mapToAttrs
		;

in rec {
	exports = self: { inherit (self)
		collectBindMounts
		;
	};

	entryToBindMount = entry: {
		mountPoint = entry.fullPath;
		device = entry.sourcePath;

		options = [ "bind" "X-fstrim.notrim" ]
			++ optional entry.hideMount "x-gvfs-hide";
	};

	collectBindMounts = datastores: let
		entries = concatLists
			(catAttrs "allEntries"
				(attrValues datastores));

		bindEntries = filter (e: e.method == "bind") entries;

		mkBindMount = entry: {
			name = entry.fullPath;
			value = entryToBindMount entry;
		};
	in
		mapToAttrs mkBindMount bindEntries;
}
