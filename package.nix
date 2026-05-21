{ stdenv, lib, fetchurl, autoPatchelfHook, version, url, nixHash }:

stdenv.mkDerivation {
  pname = "oh-my-pi";
  inherit version;

  src = fetchurl {
    inherit url;
    sha256 = nixHash;
  };

  dontUnpack = true;

  nativeBuildInputs = lib.optional stdenv.isLinux autoPatchelfHook;

  buildInputs = lib.optional stdenv.isLinux stdenv.cc.cc.lib;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/omp
    chmod +x $out/bin/omp
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