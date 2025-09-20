{ lib, buildPythonApplication, buildPythonPackage, callPackage, fetchPypi, fetchFromGitHub, python, rustPlatform, protobuf_27 }:

let
  protobuf = (protobuf_27.override {
    version = "27.3";
    hash = "sha256-JZtRNGjAns1VJ+0831AzgOaBQkHAnnLxeXs4SoXlXpE=";
  });
  python-ext4 = buildPythonPackage rec {
    pname = "python-ext4";
    version = "1.0.6";
    format = "pyproject";
    src = fetchFromGitHub {
      owner = "Eeems";
      repo = pname;
      rev = version;
      hash = "sha256-m/CnNE12n/S5/ZNn5SDCtTeEVwcckRVUbqZJjLgHC+Q=";
    };
    nativeBuildInputs = [
      python.pkgs.poetry-core
      python.pkgs.setuptools-scm
    ];
    propagatedBuildInputs = with python.pkgs; [
      (cachetools.overridePythonAttrs (prev: rec {
        version = "5.3.2";
        src = fetchPypi {
          inherit (prev) pname;
          inherit version;
          hash = "sha256-CG7kIBlveyq5yi2yUgrKMmMYto/luovE1JzKka3UUPI=";
        };
      }))
      crcmod
    ];
  };
  libconf = buildPythonPackage rec {
    pname = "libconf";
    version = "2.0.1";
    format = "setuptools";
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-L5ByWJU7pgqVqC1WM3JrR8gfLVz42IAbCSV5AW11f0o=";
    };
    nativeBuildInputs = [ python.pkgs.setuptools-scm ];
  };
  cryptography = (
    (python.pkgs.cryptography.override ({
      cryptography-vectors =
        (callPackage ../../../../development/python-modules/cryptography/vectors.nix {})
          .overridePythonAttrs (rec {
            version = "44.0.1";
            src = fetchPypi {
              pname = "cryptography_vectors";
              inherit version;
              hash = "sha256-WphmsURl3PrxK837wzkph7tVnzesi4pMm2NZvno9fqA=";
            };
          });
        })
    ).overridePythonAttrs (prev: rec {
      version = "44.0.1";
      src = fetchPypi {
        inherit (prev) pname;
        inherit version;
        hash = "sha256-9R9XBasniYr9oaqkMPNK2Q3BF0IQV3ggIu3wYAvsXxQ=";
      };

      cargoDeps = rustPlatform.fetchCargoVendor {
        inherit (prev) pname;
        inherit version src;
        hash = "sha256-hjfSjmwd/mylVZKyXsj/pP2KvAGDpfthuT+w219HAiA=";
      };
    }));
    remarkable-update-image = buildPythonPackage rec {
    pname = "remarkable-update-image";
    version = "1.1.5";
    format = "pyproject";
    src = fetchFromGitHub {
      owner = "Eeems";
      repo = pname;
      rev = version;
      hash = "sha256-nnKJYFMvcArmQFxqx+DsTY9iMJp6rffNtCOST+I6L+g=";
    };

    patches = [ ./remarkable_update_image.patch ];

    buildPhase = ''
      runHook pypaBuildPhase

      ${protobuf}/bin/protoc \
        --python_out=remarkable_update_image \
        --proto_path=protobuf \
        update_metadata.proto
    '';

    postInstall = ''
      mkdir -p $out/lib/python${lib.versions.majorMinor python.version}/site-packages/
      ls -la */*
      cp -r remarkable_update_image/* $out/lib/python${lib.versions.majorMinor python.version}/site-packages/remarkable_update_image/
    '';

    nativeBuildInputs = [
      python.pkgs.wheel
      python.pkgs.setuptools
      python.pkgs.setuptools-scm
      python.pkgs.nuitka
    ];

    propagatedBuildInputs = with python.pkgs; [
      cryptography
      (protobuf5.overridePythonAttrs (prev: rec {
        version = "5.27.3";
        src = fetchPypi {
          inherit (prev) pname;
          inherit version;
          hash = "sha256-gkYJA+ZA8rfjTugalH/arYneeW0yS8vDj/VDC83q2Cw=";
        };
      }))
      python-ext4
      libconf
      (indexed-gzip.overridePythonAttrs (prev: rec {
        version = "1.8.7";
        src = fetchPypi {
          inherit (prev) pname;
          inherit version;
          hash = "sha256-dryq1LLC+lVHj/i+m60ubGGItlX5/clCnwNGrexI92I=";
        };
      }))
    ];
  };
  remarkable-update-fuse = buildPythonPackage rec {
    pname = "remarkable-update-fuse";
    version = "1.2.4";
    format = "pyproject";
    src = fetchFromGitHub {
      owner = "Eeems-Org";
      repo = pname;
      rev = version;
      hash = "sha256-mARurPYeVwtHGZ2W0+FOLCBd9lx3eB6jdz0RQ+mJ2UY=";
    };
    nativeBuildInputs = [
      python.pkgs.wheel
      python.pkgs.setuptools
      python.pkgs.setuptools-scm
      python.pkgs.nuitka
    ];
    propagatedBuildInputs = [
      python.pkgs.fuse
      remarkable-update-image
    ];
  };
in buildPythonApplication rec {
  pname = "codexctl";
  version = "1752948641";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "jayy001";
    repo = pname;
    rev = version;
    hash = "sha256-K8HF5y4f0ybKc3fquRk4uWGAjj66yFC6/E4RUXvjF0w=";
  };

  nativeBuildInputs = [
    python.pkgs.poetry-core
  ];

  propagatedBuildInputs = with python.pkgs; [
    ((paramiko.override { inherit cryptography; }).overridePythonAttrs (prev: rec {
      version = "3.4.1";
      src = fetchPypi {
        inherit (prev) pname;
        inherit version;
        hash = "sha256-ixUwKHCvf2ZS8uA4l1wdKXPwYEbLXX1lNVZos+y+zgw=";
      };
      passthru.optional-dependencies.ed25519 = [ python.pkgs.pynacl python.pkgs.bcrypt ];
    }))
    (psutil.overridePythonAttrs (prev: rec {
      version = "6.0.0";
      src = fetchPypi {
        inherit (prev) pname;
        inherit version;
        hash = "sha256-j6rk8xC22Wn6JsoFRTOLIfc8axXbfEqNk0pUgvqoGPI=";
      };
    }))
    (requests.overridePythonAttrs (prev: rec {
      version = "2.32.4";
      src = fetchPypi {
        inherit (prev) pname;
        inherit version;
        hash = "sha256-J9AxZoLIopg00yZIIAJLYqNpQgg9Usry8UwFkTNtNCI=";
      };
    }))
    loguru
    remarkable-update-image
    remarkable-update-fuse
  ];

  meta = with lib; {
    description = "A tool to modify remarkable device versions";
    homepage = "https://github.com/jayy001/codexctl";
    license = licenses.gpl3;
    maintainers = [ ];
  };
}
