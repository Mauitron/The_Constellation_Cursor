{ pkgs, self }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "the-constellation-cursor";
  version = "0.1.0";

  src = self; 

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
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
    homepage = "https://github.com/keygenesis/The_Constellation_Cursor";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
