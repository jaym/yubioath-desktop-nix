{pkgs ? import <nixpkgs> {} }:
with pkgs;
let 
  pyscard = buildPythonPackage rec {
    name = "pyscard-${version}";
    version = "release-1.9.2-12-g087c8f2";

    src = fetchgit {
      url = "https://github.com/LudovicRousseau/pyscard";
      rev = "087c8f257f4aadafb43fafb2ae2349c2c91909de";
      sha256 = "c85860789625986652e8b96b17fc63d41b4bc7a56f0137742f7ece0418cbec63";
    };
    buildInputs = [ swig pcsclite ];

    postPatch = ''
      substituteInPlace smartcard/scard/winscarddll.c --replace "libpcsclite.so.1" "${pcsclite}/lib/libpcsclite.so.1"
    '';

    NIX_CFLAGS_COMPILE = "-I${pcsclite}/include/PCSC";
  };
in
  buildPythonApplication rec {
    name = "yubioath-desktop";
    version = "2.3.0";
    src = fetchurl {
      url = "https://github.com/Yubico/yubioath-desktop/releases/download/${name}-${version}/${name}-${version}.tar.gz";
      sha256 = "df91f1592c069ead9d0ee4653aadd5d00fe5b93f0688e6e8ad3d7116a894b12e";
    };

    postPatch = ''
      sed -i '/PySide/d' yubioath/yubicommon/setup/qt.py
      patch -p1 -d yubioath < ${./fix_library_loading.patch}
      substituteInPlace yubioath/core/legacy_otp.py --replace "ykpers-1" "${ykpers}/lib/libykpers-1.so"
    '';

    doCheck = false;

    pythonPath = with pythonPackages; [ pyside pycrypto pyscard ];

    makeWrapperArgs = ["--suffix LD_LIBRARY_PATH : \"${ykpers}/lib\"" ];

    postInstall = ''
      cp -r qt_resources $out/lib/python2.7/site-packages/yubioath/gui/
    '';
  }
