# Setup hook for Zig toolchains that, unlike the nixpkgs `zig` derivation,
# do not set `setupHook` themselves (e.g. binaries from mitchellh/zig-overlay).
# Reuses the nixpkgs hook script so `zigBuildFlags` & co. behave identically.
{
  lib,
  stdenv,
  path,
  makeSetupHook,
  xcbuild,
  zig,
}:
makeSetupHook {
  name = "zig-hook-${zig.version}";

  propagatedBuildInputs = [
    zig
  ]
  # Zig needs xcode-select (provided by xcbuild) for SDK detection.
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ xcbuild ];

  substitutions = {
    # See pkgs/development/compilers/zig/generic.nix for the rationale.
    zig_default_cpu_flag = "-Dcpu=baseline";
    zig_default_optimize_flag = "--release=safe";
  };

  meta = {
    description = "Setup hook for building packages with Zig ${zig.version}";
    inherit (zig.meta) platforms;
  };
} (path + "/pkgs/development/compilers/zig/setup-hook.sh")
