{
  lib,
  stdenv,
  fetchFromGitHub,
  zigHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "bs";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "JustAGuyTryingHisBest";
    repo = "basic-shell";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7iqcg8sWzKDYDf5hP1bjuQg142Ta0uq8QqPv/V28Cjk=";
  };

  nativeBuildInputs = [ zigHook ];

  zigBuildFlags = [ "-Dgit-revision=v${finalAttrs.version}" ];

  meta = {
    description = "A small Haskell-like scripting shell";
    homepage = "https://github.com/JustAGuyTryingHisBest/basic-shell";
    mainProgram = "bs";
    platforms = lib.platforms.unix;
  };
})
