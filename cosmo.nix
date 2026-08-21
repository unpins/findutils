# findutils via cosmoStaticCross for Windows-x86_64 (mingw blocked: pulls
# coreutils-x86_64-w64-mingw32 as a nativeBuildInputs dep and coreutils
# on mingw dies in gnulib `lib/savewd.c` on `waitpid`).
#
# Hand-rolled multicall recipe (cosmo-only — linux/darwin self-fold through
# the unpin-llvm engine instead; see flake.nix): rename main →
# {find,xargs}_main on each tool's object, ship a dispatcher.o, link
# them with libfindtools.a + lib/libfind.a + gl/lib/libgnulib.a. cosmocc
# uses ELF binutils + apelink in postFixup to produce findutils.exe.
{ unpins-lib, winTable }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;

  multicallMk = cosmoPkgs.buildPackages.writeText "unpin-multicall.mk" ''
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

  # findutils's nixpkgs derivation bakes 3 references to coreutils into the
  # build (postPatch substitutes `${coreutils}/bin/echo` into xargs.c as the
  # default command; `SORT=${coreutils}/bin/sort` configureFlag is baked into
  # the compiled binary; buildInputs = [ coreutils ] adds it as runtime dep).
  # All three are dead references for our shipped artifact: we ship find +
  # xargs only (locate/updatedb live in the `$locate` output we drop), and
  # the xargs default-echo path is never invoked on Windows (callers always
  # pass an explicit command). Override `coreutils` to the linux-native one
  # so coreutils-cross is no longer pulled into findutils-cross's drv graph
  # — that would otherwise require a cosmo-patched coreutils-cross to be
  # buildable, recreating the transitive overlay coupling we're trying to
  # remove from `nix-lib/cosmo/`.
  patched = (cosmoPkgs.findutils.override { coreutils = pkgs.coreutils; }).overrideAttrs (oa: {
    pname = "findutils-multi";

    # cosmo's <stdint.h> defines __STDC_LIMIT_MACROS as empty
    # (the C99-style guard, not a value). xargs.c uses
    # `(void) __STDC_LIMIT_MACROS;` to silence an unused-define
    # warning — with the empty macro that becomes `(void) ;`, a
    # parse error. Replace with `(void) 0;`, same semantics.
    postPatch = (oa.postPatch or "") + ''
          substituteInPlace xargs/xargs.c \
            --replace-fail '(void) __STDC_LIMIT_MACROS;' '(void) 0;'
        '';

    postBuild = (oa.postBuild or "") + ''
          # applets.list + dispatcher.c, both rendered from the ONE table the
          # flake declares (see `winTable` there). findutils is not itself a
          # program, so the table's naming rule makes a bare or unknown name
          # list instead of picking one — same as the native fold, from the
          # same rule rather than by agreement.
${winTable.emit { }}
          $CC -O2 -c -o multicall/dispatcher.o multicall/dispatcher.c

          cp find/ftsfind.o find/ftsfind.o.renamed
          cp xargs/xargs.o  xargs/xargs.o.renamed
          $OBJCOPY --redefine-sym main=find_main  find/ftsfind.o.renamed
          $OBJCOPY --redefine-sym main=xargs_main xargs/xargs.o.renamed

          install -m644 ${multicallMk} find/unpin-multicall.mk
          make -C find -f Makefile -f unpin-multicall.mk multicall-link
        '';

    postInstall = (oa.postInstall or "") + ''
          rm -f $out/bin/find $out/bin/xargs
          install -m755 multicall/findutils $out/bin/findutils
        '';
  });

in
# `findutils` → `findutils.exe` happens automatically via the cosmo
# cross stdenv's apelink setup hook.
unpins-lib.lib.withAliases cosmoPkgs
  {
    primary = "findutils.exe";
    aliases = winTable.announced;
  }
  patched
