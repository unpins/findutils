# findutils

Standalone build of [GNU findutils](https://www.gnu.org/software/findutils/) — `find` and `xargs`.

[![CI](https://github.com/unpins/findutils/actions/workflows/findutils.yml/badge.svg)](https://github.com/unpins/findutils/actions)
![Linux](https://img.shields.io/badge/Linux-%E2%9C%93-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-%E2%9C%93-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-%E2%9C%93-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

## Usage

Run a program with [unpin](https://github.com/unpins/unpin):

```bash
unpin findutils find . -name '*.md' -newer Makefile
unpin findutils find /var/log -type f -mtime +30 -delete
echo file1 file2 file3 | unpin findutils xargs rm
```

To install the programs onto your PATH:

```bash
unpin install findutils
```

`unpin install findutils` creates the `find` and `xargs` commands. `locate` / `updatedb` are not included.

## Programs

| command | what it does |
| --- | --- |
| `find` | search a directory tree for files matching expressions |
| `xargs` | build and run command lines from items read on stdin |

## Build locally

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
