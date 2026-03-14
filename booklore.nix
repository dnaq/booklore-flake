{
  lib,
  inputs,
  importNpmLock,
  buildNpmPackage,
  makeWrapper,
  nodejs,
  nodePackages,
  stdenv,
  fetchFromGitHub,
  temurin-jre-bin-25,
  yq-go,
  gradle,
  jdk25,
}:
let
  booklore-ui = buildNpmPackage (finalAttrs: {
    version = "master";
    pname = "booklore-ui";

    src = "${inputs.booklore-src}/booklore-ui";
    npmDeps = importNpmLock {
      npmRoot = "${inputs.booklore-src}/booklore-ui";
    };
    npmConfigHook = importNpmLock.npmConfigHook;

    nativeBuildInputs = [ makeWrapper ];

    buildPhase = ''
      npm run build --configuration=production
    '';

    meta = {
      description = "Web UI for Booklore";
      homepage = "https://github.com/booklore-app/booklore/tree/develop";
      license = lib.licenses.gpl3Only;
      maintainers = with lib.maintainers; [ carter ];
    };
  });
in
stdenv.mkDerivation (finalAttrs: {
  version = "master";
  pname = "booklore";

  gradle = gradle.override {
    javaToolchains = [ jdk25 ];
  };

  src = "${inputs.booklore-src}/booklore-api";

  nativeBuildInputs = [
    yq-go
    makeWrapper
    finalAttrs.gradle
  ];

  # Required for mtimCache on Darwin
  __darwinAllowLocalNetworking = true;

  mitmCache = finalAttrs.gradle.fetchDeps {
    pkg = finalAttrs.finalPackage;
    data = ./deps.json;
  };

  meta.sourceProvenance = with lib.sourceTypes; [
    fromSource
    binaryBytecode # mitm cache
  ];

  gradleFlags = [ "-Dfile.encoding=utf-8" ];

  gradleBuildTask = "clean build -x test --stacktrace";

  doCheck = false;

  postPatch = ''
    mkdir -p src/main/resources/static
    cp -r ${booklore-ui}/lib/node_modules/booklore/dist/booklore/browser/* src/main/resources/static/
    chmod -R u+w src/main/resources/static
  '';

  installPhase = ''
    mkdir -p $out/{bin,share/booklore}
    cp build/libs/booklore-api-0.0.1-SNAPSHOT.jar $out/share/booklore/booklore-api-all.jar
    makeWrapper ${temurin-jre-bin-25}/bin/java $out/bin/booklore \
    		--add-flags "-jar $out/share/booklore/booklore-api-all.jar"
  '';
})
