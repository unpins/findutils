# Changelog

## [Unreleased]

### Fixed

- On Windows, `xargs` and `find -exec` find programs on `PATH` by their plain
  name: `xargs where` or `find . -exec hostname ;` failed with `No such file or
  directory` unless you wrote `where.exe`.
- On Windows, `xargs` with no command runs `echo` from `PATH`, as on Linux and
  macOS. It pointed at a path that only existed on the build machine.
- On Linux and macOS, `findutils --unpin-program=find` (or `xargs`) prefixes
  its messages with the program's name, `find: …`, instead of `findutils: …`.

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
