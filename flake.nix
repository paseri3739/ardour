{
  description = "Ardour dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # ローカルのaubio.nixを評価してパッケージとして定義
        aubio-custom = pkgs.callPackage ./aubio.nix { };
        libraries =
          with pkgs;
          [
            boost
            glib
            glibmm
            libsndfile
            curl
            libarchive
            liblo
            taglib
            vamp-plugin-sdk
            rubberband
            libusb1
            jack2
            fftwFloat
            libpng
            pango
            cairomm
            pangomm
            lv2
            libxml2
            cppunit
            libwebsockets
            lrdf
            libsamplerate
            serd
            sord
            sratom
            lilv
            libogg
            flac
            fontconfig
            freetype
            aubio-custom
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.apple-sdk
          ];
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
            llvmPackages.clang-tools
            python311
          ];
          buildInputs = libraries;
          shellHook = ''
            # 既存の設定
            export NIX_CFLAGS_COMPILE="$(pkg-config --cflags sratom-0) $NIX_CFLAGS_COMPILE"

            # RPATHの追加
            # -Wl,-rpath, はリンカに実行時探索パスを追加する指示です
            VAMP_LIB_PATH="${pkgs.vamp-plugin-sdk}/lib"
            export LDFLAGS="-L$VAMP_LIB_PATH -Wl,-rpath,$VAMP_LIB_PATH $LDFLAGS"

            # 他のライブラリも一括で対象にする場合は以下が効率的です
            export LDFLAGS="-Wl,-rpath,${pkgs.lib.makeLibraryPath libraries} $LDFLAGS"
          '';
        };
      }
    );
}
