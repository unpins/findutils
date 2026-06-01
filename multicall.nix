# Upstream findutils is two binaries: find/find (from ftsfind.c + libfindtools.a)
# and xargs/xargs (from xargs.c). To honour the unpins one-pkg-one-bin rule we
# post-link them into a single multicall ELF/Mach-O.
#
# Why a post-link route: each tool keeps its own `int main()`. find depends on
# find/libfindtools.a (parser.o, pred.o, tree.o, …), both depend on lib/libfind.a
# + gl/lib/libgnulib.a. The cleanest path is:
#
#   1. Let `make` run upstream normally → find/find, xargs/xargs both built.
#      All .o files land in find/ and xargs/, archives in find/, lib/, gl/lib/.
#   2. Rename `main` to `find_main` / `xargs_main` on each tool's main .o via
#      objcopy --redefine-sym (branch on ABI: `_main` on Mach-O, `main` on ELF).
#   3. Compile a small dispatcher.c (basename(argv[0]) → tool_main).
#   4. Delegate the final link to find/Makefile via an injected
#      `unpin-multicall.mk`. Reason: `$(LDADD)` resolves to ~12 configure-driven
#      vars (LIB_CLOSE, LIB_SETLOCALE_NULL, LIB_MBRTOWC, LIBINTL, FINDLIBS,
#      LIB_SELINUX, MODF_LIBM, …) that differ per target. Letting make do the
#      substitution against find's own context keeps every detail intact —
#      `lib/libfind.a` and `gl/lib/libgnulib.a` get pulled in via libfindtools
#      relative paths, exactly like upstream's recipe.
#   5. Strip upstream's binaries and replace with one `findutils` plus
#      `find`/`xargs` applet symlinks. `lib.withAliases` harvests the
#      symlinks, embeds the names in UNPIN_META, and strips them.
{ lib }:
pkgs:
let
  # Custom Makefile fragment lives in find/ — find_LDADD has the union of
  # link bits both tools need (libfindtools is find-only but harmless when
  # linked into a binary that has xargs's main too). $(top_builddir) is one
  # level up so xargs/xargs.o.renamed and gl/lib/libgnulib.a resolve.
  multicallMk = pkgs.writeText "unpin-multicall.mk" ''
    MULTI_OUT ?= $(top_builddir)/multicall/findutils

    .PHONY: multicall-link
    multicall-link: $(MULTI_OUT)

    $(MULTI_OUT): \
        $(top_builddir)/multicall/dispatcher.o \
        $(top_builddir)/find/ftsfind.o.renamed \
        $(top_builddir)/xargs/xargs.o.renamed \
        libfindtools.a \
        $(top_builddir)/lib/libfind.a \
        $(top_builddir)/gl/lib/libgnulib.a
    	$(CC) $(ALL_LDFLAGS) -o $@ \
    		$(top_builddir)/multicall/dispatcher.o \
    		$(top_builddir)/find/ftsfind.o.renamed \
    		$(top_builddir)/xargs/xargs.o.renamed \
    		libfindtools.a \
    		$(top_builddir)/lib/libfind.a \
    		$(top_builddir)/gl/lib/libgnulib.a \
    		$(LIBINTL) $(LIB_CLOCK_GETTIME) $(LIB_EACCESS) $(LIB_SELINUX) \
    		$(LIB_CLOSE) $(MODF_LIBM) $(FINDLIBS) $(GETHOSTNAME_LIB) \
    		$(LIB_SETLOCALE_NULL) $(LIB_MBRTOWC)
  '';

  appletAliases = [ "find" "xargs" ];

  multicall = pkgs.pkgsStatic.findutils.overrideAttrs (old: {
    pname = "findutils-multi";

    postBuild = (old.postBuild or "") + ''
      mkdir -p multicall
      # applets.list (TSV name\tfn) for the shared Recipe-A dispatcher generator
      # (see nix-lib lib.multicallTableDispatcherC). find/xargs are 1:1; a
      # bare/unknown invocation routes to find (defaultApplet), whose getopt
      # handles --version regardless of argv[0].
      printf 'find\tfind\nxargs\txargs\n' > multicall/applets.list
${lib.multicallTableDispatcherC { name = "findutils"; defaultApplet = "find"; }}
      $CC -O2 -c -o multicall/dispatcher.o multicall/dispatcher.c

      # Source-level rename: pre-process ftsfind.c/xargs.c with
      # `-Dmain=<tool>_main` so cpp rewrites the name BEFORE compilation,
      # producing .o (fat-LTO bitcode + native) where the symbol is
      # already `find_main`/`xargs_main` on both sides.
      #
      # The natural alternative — `objcopy --redefine-sym` on the existing
      # .o — only renames the native side; lto-plugin reads the bitcode
      # side at final link and still sees `main`, leaving the dispatcher's
      # `find_main`/`xargs_main` refs unresolved. `ld -r` to materialize
      # bitcode → native first doesn't help either: gcc's ld -r preserves
      # the bitcode side (output is again fat) unless we go through
      # `-flinker-output=nolto-rel`, which then loses the LTO benefit for
      # this object anyway.
      #
      # CPPFLAGS override is safe: automake's compile rule is
      # `$(CC) $(DEFS) $(DEFAULT_INCLUDES) $(INCLUDES) $(AM_CPPFLAGS) $(CPPFLAGS) …`
      # — DEFS (HAVE_CONFIG_H etc.) and INCLUDES come from configure
      # output, not from the env CPPFLAGS we replace here.
      rm -f find/ftsfind.o xargs/xargs.o
      make -C find  ftsfind.o CPPFLAGS="-Dmain=find_main"
      make -C xargs xargs.o   CPPFLAGS="-Dmain=xargs_main"
      mv find/ftsfind.o find/ftsfind.o.renamed
      mv xargs/xargs.o  xargs/xargs.o.renamed

      install -m644 ${multicallMk} find/unpin-multicall.mk
      make -C find -f Makefile -f unpin-multicall.mk multicall-link
    '';

    postInstall = (old.postInstall or "") + ''
      rm -f $out/bin/find $out/bin/xargs
      install -m755 multicall/findutils $out/bin/findutils
      for n in ${lib.concatStringsSep " " appletAliases}; do
        ln -s findutils $out/bin/$n
      done
    '';
  });
in
lib.withAliases pkgs
  {
    primary = "findutils";
    aliasesFromSymlinksIn = "bin";
  }
  multicall
