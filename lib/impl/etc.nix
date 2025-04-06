{ self, ... }:

let
	inherit (builtins)
		attrValues
		concatMap
		;

	inherit (self)
		mapToAttrs
		;

in rec {
	exports = self: { inherit (self)
		collectEtc
		;
	};

	mkEtcEntry = entry: {
		name = entry.path;
		value = {
			source = entry.sourcePath;
			mode = "symlink";
		};
	};

	collectEtc = datastores: let
		allEtc = concatMap
				(v: v.etc.allEntries)
				(attrValues datastores);
	in
		mapToAttrs mkEtcEntry allEtc;
}
