{
  description = "Standalone build of findutils";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Linux/macOS: pkgsStatic.findutils via mkStandaloneFlake → post-link
  # multicall recipe in `nix-lib/native/findutils.nix` combines `find` +
  # `xargs` into a single `findutils` binary (lib.withAliases embeds the
  # applet names as UNPIN_META). Windows: routed through Cosmopolitan
  # (`windowsCosmo = true`) because mingw findutils pulls coreutils as a
  # nativeBuildInputs dep, and coreutils on mingw fails in gnulib
  # (lib/savewd.c waitpid) — see docs/platforms/mingw.md. The cosmo path
  # has the same multicall recipe in `nix-lib/cosmo/findutils.nix`.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "findutils";
      windowsCosmo = true;
      smoke = [ "--version" ];
      smokePattern = "find \\(GNU findutils\\)";
    };
}
