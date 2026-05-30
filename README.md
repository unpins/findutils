# findutils

Standalone build of [GNU findutils](https://www.gnu.org/software/findutils/) — `find` and `xargs`.

[![CI](https://github.com/unpins/findutils/actions/workflows/findutils.yml/badge.svg)](https://github.com/unpins/findutils/actions)
![Linux](https://img.shields.io/badge/Linux-%E2%9C%93-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-%E2%9C%93-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-%E2%9C%93-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

Ships one multicall executable, `findutils`; `unpin findutils` materializes `find` and `xargs` shims that dispatch by `argv[0]`. `locate` / `updatedb` are not included.

## Installation

```bash
unpin findutils        # install
unpin run findutils    # run without installing
```

## Usage

```bash
find . -name '*.md' -newer Makefile
find /var/log -type f -mtime +30 -delete
echo file1 file2 file3 | xargs rm
find . -name '*.o' -print0 | xargs -0 rm
```

## Build

```bash
nix build
./result/bin/findutils --version
```

Linux x86_64 ~432 KB stripped; Windows x86_64 (via Cosmopolitan) ~1.1 MB.

## Man pages

`find.1` and `xargs.1` are embedded in the binary — read with `unpin man findutils`.

## Manual download

The [Releases](https://github.com/unpins/findutils/releases) page has standalone binaries.

## License

GPL-3.0-or-later (upstream findutils).
