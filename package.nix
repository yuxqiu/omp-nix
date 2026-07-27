{ stdenv, lib, fetchurl, makeWrapper, patchelf, version, url, nixHash }:

let
  omp-bin = stdenv.mkDerivation {
    pname = "oh-my-pi-bin";
    inherit version;

    src = fetchurl {
      inherit url;
      sha256 = nixHash;
    };

    dontUnpack = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp $src $out/bin/omp
      chmod +x $out/bin/omp
      runHook postInstall
    '';
  };

  isLinux = stdenv.hostPlatform.isLinux;
  interpreter = "${stdenv.cc.bintools.dynamicLinker}";

in stdenv.mkDerivation {
  pname = "oh-my-pi";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ] ++ lib.optional isLinux patchelf;

  # The release artifact is a Bun single-file executable: the JS bundle lives in
  # a `.bun` PROGBITS section (~91 MiB) that the Bun runtime locates by reading
  # its own executable image at startup. Letting the default fixupPhase strip it
  # breaks that lookup -- the section itself survives, but the binary no longer
  # initialises its module graph and degrades to a bare Bun runtime, so
  # `omp --version` prints the Bun version (1.3.x) and every omp subcommand
  # disappears. Setting the interpreter with patchelf is safe on its own: the
  # `.bun` bytes come through byte-identical, only shifted. So only the
  # strip/rpath-shrink fixups need suppressing.
  dontStrip = true;
  dontPatchELF = true;

  installPhase =
    if isLinux then ''
      runHook preInstall
      mkdir -p $out/bin
      install -m755 ${omp-bin}/bin/omp $out/bin/omp
      patchelf --set-interpreter ${interpreter} $out/bin/omp
      runHook postInstall
    '' else ''
      runHook preInstall
      mkdir -p $out/bin
      makeWrapper ${omp-bin}/bin/omp $out/bin/omp
      runHook postInstall
    '';

  meta = with lib; {
    description = "A coding agent with the IDE wired in";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = licenses.mit;
    mainProgram = "omp";
    platforms = [ stdenv.hostPlatform.system ];
  };
}