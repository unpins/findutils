# findutils

Standalone build of [GNU findutils](https://www.gnu.org/software/findutils/) — `find` and `xargs`.

[![CI](https://github.com/unpins/findutils/actions/workflows/findutils.yml/badge.svg)](https://github.com/unpins/findutils/actions)
![Linux](https://img.shields.io/badge/Linux-%E2%9C%93-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-%E2%9C%93-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-%E2%9C%93-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

## Usage

The package ships one multicall executable, `findutils`. `unpin install` materializes `find` and `xargs` shims next to it; dispatch is by `argv[0]`.

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

Linux x86_64 ships ~432 KB stripped; Windows x86_64 (via Cosmopolitan) ~1.1 MB.

## License

GPL-3.0-or-later (upstream findutils).
