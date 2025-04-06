{ self, prelude, lib, ... }:

let
	inherit (builtins)
		map
		listToAttrs
		;

in rec {
	exports = self: { inherit (self)
		mapToAttrs
		;
	};

	##
	# mapToAttrs : (a -> Mapping b) -> [a] -> Dict b
	mapToAttrs = f: list: listToAttrs (map f list);
}
