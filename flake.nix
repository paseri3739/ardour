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

        # ビルド定義の本体
        ardour-package = pkgs.stdenv.mkDerivation {
          pname = "ardour";
          version = "8.x"; # 必要に応じて適切なバージョンに変更してください

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
          # prefix=$out を指定することで、ビルド結果が /nix/store/... にインストールされます
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

          # RPATHの解決（Nixのビルドプロセスで自動的に行われますが、
          # 特殊なライブラリパスが必要な場合に備えて設定を維持します）
          preFixup = ''
            # 必要に応じて install_name_tool やラッピング処理をここに記述
          '';
        };
      in
      {
        # nix build . で実行されるパッケージ
        packages.default = ardour-package;

        # nix develop で提供される開発環境
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
            VAMP_LIB_PATH="${pkgs.vamp-plugin-sdk}/lib"
            export LDFLAGS="-L$VAMP_LIB_PATH -Wl,-rpath,$VAMP_LIB_PATH $LDFLAGS"

            # 他のライブラリも一括で対象にする
            export LDFLAGS="-Wl,-rpath,${pkgs.lib.makeLibraryPath libraries} $LDFLAGS"
          '';
        };
      }
    );
}
