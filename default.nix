{ system ? builtins.currentSystem
, crossSystem ? null
# allows to cutomize haskellNix (ghc and profiling, see ./nix/haskell.nix)
, config ? {}
# allows to override dependencies of the project without modifications,
# eg. to test build against local checkout of bcc-nix:
# nix build -f default.nix bcc-node --arg sourcesOverride '{
#   bcc-nix = ../bcc-nix;
# }'
, sourcesOverride ? {}
# pinned version of nixpkgs augmented with overlays (bcc-nix and our packages).
, pkgs ? import ./nix { inherit system crossSystem config sourcesOverride; }
, gitrev ? pkgs.bccNix.commitIdFromGitRepoOrZero ./.git
}:
with pkgs; with commonLib;
let

  haskellPackages = recRecurseIntoAttrs
    # we are only interested in listing the project packages:
    (selectProjectPackages bccPreludeHaskellPackages);

  self = {
    inherit haskellPackages check-hydra;

    inherit (haskellPackages.bcc-prelude.identifier) version;

    # `tests` are the test suites which have been built.
    tests = collectComponents' "tests" haskellPackages;
    # `benchmarks` (only built, not run).
    benchmarks = collectComponents' "benchmarks" haskellPackages;

    checks = recurseIntoAttrs {
      # `checks.tests` collect results of executing the tests:
      tests = collectChecks haskellPackages;
    };

    shell = import ./shell.nix {
      inherit pkgs;
      withHoogle = true;
    };
};
in self

#TODO - verify overides