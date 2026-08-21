{
  description = "findutils as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Linux/macOS: the unpin-llvm engine compiles pkgsStatic.findutils to bitcode
  # and the standalone self-folds `find` + `xargs` into one `findutils` binary
  # (the applet names ship as embedded aliases).
  # Windows: routed through Cosmopolitan (`windowsBuild = import ./cosmo.nix
  # …`) because mingw findutils pulls coreutils as a nativeBuildInputs dep,
  # and coreutils on mingw fails in gnulib (lib/savewd.c waitpid) — see
  # docs/platforms/mingw.md. The cosmo path carries its own objcopy multicall
  # recipe inline in `./cosmo.nix` (cosmocc is ELF, no engine).
  outputs = { self, unpins-lib }:
    let
      # The windows fold's whole dispatch table, declared once: ./cosmo.nix
      # renders applets.list and the dispatcher from it, `withAliases` announces
      # it, and `multicall.windowsTable` hands the same value to CI — which is
      # the only way CI can check the .exe against anything but itself.
      programs = [{ name = "find"; } { name = "xargs"; }];
      winTable = unpins-lib.lib.multicallTableOf { name = "findutils"; inherit programs; };
    in
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "findutils";
      windowsBuild = import ./cosmo.nix { inherit unpins-lib winTable; };
      smoke = [ "--unpin-program=find" "--version" ];
      smokePattern = "find \\(GNU findutils\\)";

      # Build via the unpin-llvm engine + emit a bitcode multicall module. The
      # standalone self-folds `find` + `xargs` from the captured module.bc (no
      # hand-rolled objcopy fold — that recipe can't run on the engine's -flto
      # bitcode objects). The bitcode multicall hook captures each program's
      # link and emits module.bc; the mega merges them.
      engine = "unpin-llvm";
      multicall = {
        inherit programs;
        windowsTable = winTable;
      };
      # nixpkgs hard-codes two coreutils store paths into findutils: xargs's
      # default command (`postPatch` rewrites `default_cmd[] = "echo"` →
      # `"${coreutils}/bin/echo"`) and locate's `SORT=${coreutils}/bin/sort`
      # configureFlag. The echo path lands in the shipped find/xargs binary as a
      # runtime-closure ref to coreutils — against the no-/nix/store rule. Drop
      # nixpkgs' postPatch so xargs keeps bare `"echo"` (looked up on PATH, like
      # diffutils' bare `pr`), and bare-name SORT (only locate, an output we
      # drop, used it). On darwin also swap coreutils for the native build one:
      # pkgsStatic.coreutils drags pkgsStatic.gmp-with-cxx, whose configure
      # rejects the static build-clang on the Mac builder; coreutils is only a
      # build-time input now, so this is safe (same override cosmo.nix uses).
      build = pkgs:
        let
          base =
            if pkgs.stdenv.hostPlatform.isDarwin
            then pkgs.pkgsStatic.findutils.override { coreutils = pkgs.buildPackages.coreutils; }
            else pkgs.pkgsStatic.findutils;
        in
        base.overrideAttrs (old: {
          # Skip `make check`: findutils' own find/xargs testsuites pass, but the
          # bundled gnulib-tests (getopt + multi-threaded meta-tests) fail under
          # static-musl threads in the sandbox — same as diffutils. There's no
          # clean way to run only the package's tests, so disable the suite.
          doCheck = false;
          postPatch = "";
          configureFlags =
            (builtins.filter (f: !(pkgs.lib.hasPrefix "SORT=" f)) (old.configureFlags or [ ]))
            ++ [ "SORT=sort" ];
        });
    };
}
