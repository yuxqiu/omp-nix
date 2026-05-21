{ stdenv, lib, fetchurl, makeWrapper, version, url, nixHash }:

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

  nativeBuildInputs = [ makeWrapper ];

  installPhase =
    if isLinux then ''
      runHook preInstall
      mkdir -p $out/bin
      makeWrapper ${interpreter} $out/bin/omp \
        --argv0 omp \
        --set BUN_SELF_EXE ${omp-bin}/bin/omp \
        --add-flags ${omp-bin}/bin/omp
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