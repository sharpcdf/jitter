# Jitter
A repository-based binary manager for Linux

## How it works
Jitter searches through GitHub(and hopefully soon more sources) for releases with `.tar.gz`, `.tgz`, `.zip` or `.AppImage` assets. Unlike Homebrew or similar package managers, Jitter does not require a brewfile or nixfile in order to recognize the project.

## Installing
Using the `install.sh` script (recommended):
```
wget -qO- https://raw.githubusercontent.com/sharpcdf/jitter/main/install.sh | bash
```
Through nimble:
```
nimble install https://github.com/sharpcdf/jitter
```
## Notes
- At the moment, Jitter is being developed and you need at least version 0.3.0 to use the install script. Previous releases relied on an installer called Mug.
- You may encounter bugs as this project is still in development, please create an issue if you encounter anything wrong with jitter :)
- With the release of Jitter 0.3.0, many things broke and are being worked on. If you find a bug with a command or flag, please tell us so we can fix it

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

### Example Usage
1. `jtr install gh:VSCodium/vscodium` - installs repository VSCodium/vscodium from github.
2. `jtr install vscodium` - searches for all repositories that have the name `vscodium`, and then installs the chosen one
3. `jtr search vscodium` - searches and lists all repositories that have `vscodium` in their name.
4. `jtr search VSCodium/vscodium` - searches and lists all release tags of repository `VSCodium/vscodium`
5. `jtr list` - lists all executables in jitter's bin.
6. `jtr catalog` - lists all downloaded repositories
7. `jtr remove VSCodium/vscodium` - removes VSCodium/vscodium from your system
8. `jtr install VSCodium/vscodium@1.69.0` - installs VSCodium/vscodium release with the tag `1.69.0`
9. `jtr update VSCodium/vscodium` - updates vscodium to the latest version
10. `jtr update (this|jitter|jtr)` - updates jitter to the latest release
11. `jtr update all` - updates all installed packages

Note: repositories are case insensitive, and all AppImage file names are converted to the name of the repository. `jtr install VSCodium/vscodium` is equivalent to `jtr install vscodium/vscodium`.
