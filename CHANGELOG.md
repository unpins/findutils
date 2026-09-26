# Changelog

## [Unreleased]

## [4.10.0-2] - 2026-09-26

### Fixed

- `xargs` with no command works again. It defaults to `echo`, and the build had
  baked an absolute `/nix/store/…/bin/echo` path into the binary — a path that
  does not exist on your machine — so every such run died with `No such file or
  directory`. The bare name is looked up on `PATH` now.

### Changed

- A program inside the binary is selected with `--unpin-program=<name>`:
  `findutils --unpin-program=xargs rm`. The positional form
  (`findutils xargs …`) and the fallback to `find` for an unrecognised name are
  gone; a bare or unknown name lists the two programs instead of quietly
  behaving as one of them. The installed `find` and `xargs` commands are
  unaffected — this only concerns running the multi-program binary directly.

- Built by the same compiler as the rest of the catalog. The Linux x86_64
  binary grew from 442 KB to 544 KB; behaviour is unchanged.
