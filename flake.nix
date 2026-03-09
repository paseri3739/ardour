{
  description = "Ardour dependencies and build environment";

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

        # ローカルの定義ファイルを評価
        aubio-custom = pkgs.callPackage ./aubio.nix { };
        vamp-custom = pkgs.callPackage ./vamp.nix { };

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
            vamp-custom # 標準の vamp-plugin-sdk の代わりにカスタム版を使用
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
            fluidsynth # external
            hidapi # external
            libltc # external
            qm-dsp # external
            kissfft # external
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            pkgs.apple-sdk
          ];

        ardour-package = pkgs.stdenv.mkDerivation {
          pname = "ardour";
          version = "8.x";

          src = ./.; # カレントディレクトリのソースを使用

          nativeBuildInputs = with pkgs; [
            pkg-config
            python311
            perl
            gettext
            itstool
          ];

          buildInputs = libraries;

          # 環境変数の設定
          CFLAGS = "-DDISABLE_VISIBILITY";
          CXXFLAGS = "-DDISABLE_VISIBILITY";

          # configureフェーズ
          configurePhase = ''
            python3 waf configure \
              --prefix=$out \
              --arm64 \
              --strict \
              --ptformat \
              --libjack=weak \
              --optimize \
              --keepflags
          '';

          # buildフェーズ
          buildPhase = ''
            python3 waf
          '';

          # installフェーズ
          installPhase = ''
            python3 waf install
          '';

        };
      in
      {
        packages.default = ardour-package;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
            python311
          ];
          buildInputs = libraries;
          shellHook = ''
            export NIX_CFLAGS_COMPILE="$(pkg-config --cflags sratom-0) $NIX_CFLAGS_COMPILE"

            mkdir -p .pkgconfig
            ln -sf ${pkgs.hidapi}/lib/pkgconfig/hidapi.pc .pkgconfig/hidapi-hidraw.pc
            export PKG_CONFIG_PATH="$(pwd)/.pkgconfig:$PKG_CONFIG_PATH"
          '';
        };
      }
    );
}
