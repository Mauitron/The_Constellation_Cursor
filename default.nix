{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "the-constellation-cursor";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "keygenesis";
    repo = "The_Constellation_Cursor";
    rev = "main";
    sha256 = "sha256-zc0rE8yw4NiEiVkXlXcIDTxqQsuzQaTYMV23sRVw6Gs=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };

  buildInputs = with pkgs; [
    libdrm
  ];

  libraryName = "libthe_constellation_cursor.so";

  postInstall = ''
    mkdir -p $out/share/doc/${pname}
    cp README.md $out/share/doc/${pname}/
    cp cursor_designer.html $out/share/doc/${pname}/
  '';

  meta = with pkgs.lib; {
    description = "System vector cursor for Linux using LD_PRELOAD to bypass compositor cursor rendering on the DRM hardware cursor plane.";
    homepage = "https://github.com/Mauitron/The_Constellation_Cursor";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
