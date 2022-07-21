# Jitter
A git-based binary manager for linux written in Nim.

## How it works?
Jitter searches through GitHub for releases with `.tar.gz`, `.tgz` or `.zip` assets. Unlike Homebrew or similar package managers, jitter does not require a brewfile or nixfile in order to recognize the project.

## Installing
```
wget -qO - https://github.com/sharpcdf/jitter/blob/main/install.sh?raw=true | sh
```

## Building
Clone the repository and run `nimble build`.
(You need to have nim and nimble installed).
```
git clone https://github.com/sharpcdf/jitter
cd jitter
nimble build
```

## Usage
```
$ jtr
A git-based binary manager for linux.

Usage:
   [options] COMMAND

Commands:

  install          Installs the binaries of the given repository, if avaliable.                         [gh:][user/]repo[@tag]
  update           Updates the specified binaries, or all binaries if none are specified.               user/repo[@tag]
  remove           Removes the specified binaries from your system.                                     user/repo[@tag]
  search           Searches for binaries that match the given repositories, returning them if found.    [user/]repo
  list             Lists all executables downloaded.
  catalog          Lists all installed packages.

Options:
  -h, --help
  -v, --version

```
### Examples
- `jtr install gh:VSCodium/vscodium`: installs repository VSCodium/vscodium from GitHub.
- `jtr install vscodium`: searches for all repositories that have the name `vscodium`, and then installs the chosen one.
- `jtr search vscodium`: searches and lists all repositories that have `vscodium` in their name.
- `jtr search VSCodium/vscodium (tag|tags|true)`: searches and lists all release tags of repository `VSCodium/vscodium`
- `jtr list`: lists all executables in Jitter's bin.
- `jtr catalog`: lists all downloaded repositories
- `jtr remove VSCodium/vscodium`: removes VSCodium/vscodium from your system.
- `jtr install VSCodium/vscodium@1.69.0`: installs VSCodium/vscodium release with the tag `1.69.0`.
- `jtr update VSCodium/vscodium`: updates vscodium to the latest version.
- `jtr update (this|jitter|jtr)`: updates jitter to the latest release.

## About
Your about info.
