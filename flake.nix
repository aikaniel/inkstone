{
  description = "PHP Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    eachSupportedSystem = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

    pkgs = eachSupportedSystem (system: nixpkgs.legacyPackages.${system}.extend (final: prev: {
      meteor = prev.meteor.overrideAttrs (finalAttrs: previousAtters:
      let
        version = "3.4";
        srcs = {
          x86_64-linux = prev.fetchurl {
            url = "https://static.meteor.com/packages-bootstrap/${version}/meteor-bootstrap-os.linux.x86_64.tar.gz";
            hash = "sha256-tzzRN9UAH7+BM3fs76U5H20vD0LGMpdrMDDiJtchgEg=";
          };
          x86_64-darwin = prev.fetchurl {
            url = "https://static.meteor.com/packages-bootstrap/${version}/meteor-bootstrap-os.osx.x86_64.tar.gz";
            hash = "sha256-Z9Had9hscEjxHch19KCYUTqN4OikYLfz1tqEpyxw2Y8=";
          };
          aarch64-darwin = prev.fetchurl {
            url = "https://static.meteor.com/packages-bootstrap/${version}/meteor-bootstrap-os.osx.arm64.tar.gz";
            hash = "sha256-AT7njZTgf/WTHlvLEbF3dXKNoqyqHy8KloBQ4gsbPuM=";
          };
        };
      in
      {
        inherit version;

        buildInputs = [
          prev.patchelf
        ];

        src = srcs.${system} or (throw "unsupported system ${system}");

        preFixup = prev.lib.optionalString prev.stdenv.hostPlatform.isUnix ''
          # Cleanup symlinks from the extracted meteor build
          find $out -xtype l -delete
        '';

        meta = {
          description = "Complete open source platform for building web and mobile apps in pure JavaScript";
          homepage = "https://www.meteor.com/";
          sourceProvenance = with prev.lib.sourceTypes; [ binaryNativeCode ];
          license = prev.lib.licenses.mit;
          platforms = prev.lib.systems.flakeExposed;
          maintainers = [ ];
          mainProgram = "meteor";
        };

      });

    }));

  in
  {
    devShells = eachSupportedSystem (system: {
      default = pkgs.${system}.mkShell {
        buildInputs = [
          pkgs.${system}.meteor
        ];

        shellHook = ''
          source .envrc &> /dev/null
        '';
      };
    });

  };
}
