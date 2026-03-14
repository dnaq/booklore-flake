{
  lib,
  booklore-src,
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

  # upstream = fetchFromGitHub {
  #   owner = "booklore-app";
  #   repo = "booklore";
  #   rev = "develop";
  #   hash = "sha256-8as/D34nwVcO5JwkBqq4ougGtC7aw6u6utekTwH9tx8=";
  # };
  booklore-ui = buildNpmPackage (finalAttrs: {
    version = "main";
    pname = "booklore-ui";

    src = "${booklore-src}/booklore-ui";

    # sourceRoot = "${finalAttrs.src}/booklore-ui";

    npmDepsHash = "sha256-JXjRi4vPpIU++pBqpn1JBJB9pOPBxvg2Es10+ckWPFA=";

    # npmPackFlags = [ "--ignore-scripts" ];

    nativeBuildInputs = [ makeWrapper ];

    # npmFlags = [ "--legacy-peer-deps" ];
    # makeCacheWritable = true;

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
  version = "main";
  pname = "booklore";

  gradle = gradle.override {
    javaToolchains = [ jdk25 ];
  };

  src = "${booklore-src}/booklore-api";

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

  /*
    	# Copied from booklores docker build instructions
        			# export APP_VERSION=${version}
        			# yq eval '.app.version = strenv(APP_VERSION)' -i src/main/resources/application.yaml
  */
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
