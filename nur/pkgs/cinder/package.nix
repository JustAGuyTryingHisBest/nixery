# Credit owed to the following PR for doing 99% of the work.
# I had to do some tomfoolery to get this running on aarch64-darwin because
# not all the sAmPlEs could be compiled on non-linux oses.
#
# https://github.com/NixOS/nixpkgs/pull/464976
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  pkg-config,
  glib,
  zlib,
  curl,
  libGLX,
  libx11,
  libxcb,
  libxrandr,
  libxinerama,
  libxcursor,
  libxi,
  fontconfig,
  pulseaudio,
  expat,
  libmpg123,
  libsndfile,
  libsysprof-capture,
  patchelf,
  fixDarwinDylibNames,
  gst_all_1,
  cairo,

  headless ? false,
  enableAudio ? false,
  enableVideo ? false,

  buildTests ? true,
  buildAllSamples ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cinder";
  version = "0.9.3";

  src = fetchFromGitHub {
    owner = "cinder";
    repo = "Cinder";
    tag = "v${finalAttrs.version}";
    hash = "sha256-IPF8/PQ9iWmXwwJ6MBGtkbNcpOzW8VnyMaBRxXIN6DQ=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    fixDarwinDylibNames
  ]
  ++ lib.optionals buildAllSamples [
    cairo
    patchelf
  ];

  propagatedBuildInputs = [
    libGLX
    curl
    fontconfig
    zlib
    libx11
    libxcb
    libxrandr
    libxinerama
    libxcursor
    libxi
    expat
  ]
  ++ lib.optionals enableAudio [
    pulseaudio
    libmpg123
    libsndfile
  ]
  ++ lib.optionals enableVideo [
    glib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    libsysprof-capture
  ];

  __structuredAttrs = true;
  strictDeps = true;

  patches = [
    (fetchpatch {
      # Remove when updating to a release containing https://github.com/cinder/Cinder/pull/2386.
      name = "001-fixDisableVideo";
      url = "https://github.com/cinder/Cinder/commit/94230d6dd42305c3f404a8fafd4f0fb1934349fa.patch";
      hash = "sha256-xEWv/Zp6wMvxAOAy0BFPadhHlDGL95DrvDh9n/KRUIs=";
    })
    (fetchpatch {
      name = "002-fixTimelineSamples";
      url = "https://github.com/cinder/Cinder/commit/c7530ef4f2161be8e9e9fb4b4cafae6521272dc4.patch";
      hash = "sha256-m5duVHNEmefy3mWbFXo6xBtUAOMaEkpednmNmH0JR+Y=";
    })
  ];

  postPatch = ''
    substituteInPlace \
      proj/cmake/modules/FindMPG123.cmake \
      proj/cmake/modules/FindSNDFILE.cmake \
      --replace-fail "NO_DEFAULT_PATH" ""

    # The zlib-1.1.x vendored inside freetype skips its `Byte` typedef whenever
    # TARGET_OS_MAC is defined, on the classic-Mac assumption that MacTypes.h
    # then supplies it. Apple's SDK defines TARGET_OS_MAC from
    # <TargetConditionals.h>, which any libc header pulls in, but never includes
    # MacTypes.h here -- so `Byte` stays undefined and `typedef Byte FAR Bytef`
    # fails to compile. Upstream zlib fixed this by keying the guard off
    # MacTypes.h's own include guard instead.
    substituteInPlace src/freetype/gzip/ftzconf.h \
      --replace-fail \
        "#if !defined(MACOS) && !defined(TARGET_OS_MAC)" \
        "#if !defined(__MACTYPES__)"
  ''
  + lib.optionalString buildAllSamples ''
    # Windows-specific samples
    rm -r samples/D3d11*
    rm -r samples/_opengl/NvidiaMulticast

    # They don't work cause of missing blocks for Linux
    rm -r samples/LocationManager
    rm -r samples/MotionBasic

    rm -r samples/QuickTime*
    rm -r samples/ios*

    rm -r samples/Renderer2dBasic
  '';

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
  ]
  ++ lib.optionals headless [ "-DCINDER_HEADLESS=ON" ]
  ++ lib.optionals (enableVideo) [ "-DCINDER_DISABLE_VIDEO=ON" ]
  ++ lib.optionals (enableAudio) [ "-DCINDER_DISABLE_AUDIO=ON" ]
  ++ lib.optionals finalAttrs.finalPackage.doCheck [ "-DCINDER_BUILD_TESTS=ON" ]
  ++ lib.optionals buildAllSamples [ "-DCINDER_BUILD_ALL_SAMPLES=ON" ];

  doCheck = buildTests;

  installPhase = ''
    runHook preInstall

    mkdir $out

    mkdir -p $out/include
    mkdir -p $out/lib/cmake/Cinder

    # Cinder's public headers include its vendored third-party libraries
    # directly -- cinder/Vector.h pulls in glm/vec2.hpp, the GL headers pull in
    # glad and KHR -- and upstream exports the whole include/ tree as its
    # interface include directory. Installing only include/cinder leaves every
    # consumer unable to compile a single #include.
    cp -r ../include/. $out/include/

    find .. -name "libcinder.*" -exec cp {} $out/lib/ \;

    find lib -name "cinderTargets.cmake" -exec cp {} $out/lib/cmake/Cinder/ \;

    ${lib.optionalString buildAllSamples ''
      mkdir -p $out/share/cinder/samples
      mkdir -p $out/bin

      cp -Lr Release/* $out/share/cinder/samples
      rm -r $out/share/cinder/samples/UnitTests

      find "$out/share/cinder/samples" -mindepth 2 -maxdepth 2 -type f -executable \
        -exec patchelf --shrink-rpath --allowed-rpath-prefixes "$NIX_STORE" {} \;

      find "$out/share/cinder/samples" -mindepth 2 -maxdepth 2 -type f -executable \
        -exec sh -c 'ln -s "$1" "$0/bin/cinder_$(basename "$1")"' "$out" {} \;
    ''}

    runHook postInstall
  '';

  meta = {
    description = "Peer-reviewed, free, open source C++ library for creative coding";
    homepage = "https://libcinder.org";
    license = lib.licenses.bsd2;
    maintainers = [ ];
  };
})
