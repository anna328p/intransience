{ pkgs, lib, localLib, ... }:

let
	im = lib.evalModules {
		modules = [
			{ _module.check = false; }
			{ _module.args = { inherit localLib; }; }
			./module.nix
		];
	};

	doc = pkgs.nixosOptionsDoc {
		inherit (im) options;

		warningsAreErrors = false;

		transformOptions = opt:
			if opt.name == "_module.args"
				then opt // { visible = false; }
				else opt;
	};

	md = pkgs.runCommand "options-doc.md" {} ''
		cat ${doc.optionsCommonMark} >> $out
	'';

in
	pkgs.stdenv.mkDerivation {
		pname = "options-doc";
		version = "0";

		dontUnpack = true;

		nativeBuildInputs = [ pkgs.mdbook ];

		buildPhase = ''
			mkdir src

			cat >src/SUMMARY.md <<-EOF
			# Summary

			- [Options](options.md)
			EOF

			mdbook init . \
				--title="intransience options" \
				--ignore=none

			cp ${md} src/options.md

			mkdir -p $out
			mdbook build -d $out
		'';

		dontInstall = true;
	}
