{
  pkgs,
  lib,
}: let
  python3Packages = pkgs.python3Packages;

  # Transitive dependency, not yet in nixpkgs. Only consumed by splunk-as,
  # so it is defined inline rather than exposed as a top-level flake package.
  assistant-skills-lib = python3Packages.buildPythonPackage rec {
    pname = "assistant-skills-lib";
    version = "1.0.1";
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "assistant_skills_lib";
      inherit version;
      hash = "sha256-WMMeVMc+iwl7dGgp1JNDCAH/No88/XmJHWV33BlFvV8=";
    };

    build-system = [python3Packages.hatchling];

    dependencies = [
      python3Packages.requests
      python3Packages.tabulate
    ];

    pythonImportsCheck = ["assistant_skills_lib"];

    # Tests are not shipped in the sdist.
    doCheck = false;

    meta = {
      description = "Shared Python utilities for building Claude Code Assistant Skills plugins";
      homepage = "https://github.com/grandcamel/assistant-skills-lib";
      license = lib.licenses.mit;
    };
  };
in
  python3Packages.buildPythonApplication rec {
    pname = "splunk-as";
    version = "1.2.0";
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "splunk_as";
      inherit version;
      hash = "sha256-O404DWLU9fGppTxRSNoNpVjbj+bjdb6Q38RGD861es4=";
    };

    build-system = [python3Packages.hatchling];

    dependencies = [
      python3Packages.requests
      python3Packages.click
      assistant-skills-lib
    ];

    pythonImportsCheck = ["splunk_as"];

    # Tests are not shipped in the sdist.
    doCheck = false;

    meta = {
      description = "Python library and CLI for interacting with the Splunk REST API";
      homepage = "https://github.com/grandcamel/splunk-as";
      license = lib.licenses.mit;
      mainProgram = "splunk-as";
    };
  }
