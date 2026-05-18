{
  description = "Standalone build of findutils";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Linux/macOS: pkgsStatic.findutils → post-link multicall recipe in
  # ./multicall.nix combines `find` + `xargs` into a single `findutils`
  # binary (lib.withAliases embeds the applet names as UNPIN_META).
  # Windows: routed through Cosmopolitan (`windowsBuild = import ./cosmo.nix
  # …`) because mingw findutils pulls coreutils as a nativeBuildInputs dep,
  # and coreutils on mingw fails in gnulib (lib/savewd.c waitpid) — see
  # docs/platforms/mingw.md. The cosmo path has the same multicall recipe
  # inline in `./cosmo.nix`.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "findutils";
      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };
      smoke = [ "--version" ];
      smokePattern = "find \\(GNU findutils\\)";
      build = pkgs:
        import ./multicall.nix {
          lib = pkgs.lib // unpins-lib.lib;
        } pkgs;
    };
}
