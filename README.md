# Jitter
A repository-oriented binary manager for Linux

## How it works
Jitter searches through GitHub(and hopefully soon more sources) for releases with `.tar.gz`, `.tgz`, `.zip` or `.AppImage` assets. Unlike Homebrew or similar package managers, Jitter does not require a brewfile or nixfile in order to recognize the project.

## Installing
Before installing, make sure you have glibc installed on your distro.

Using the `install.sh` script (recommended):
```
wget -qO- https://github.com/sharpcdf/jitter/raw/main/install.sh | bash
```
To pass flags such as `--force` or `--uninstall` use:
```
wget -qO- https://github.com/sharpcdf/jitter/raw/main/install.sh | bash -s -- --flag
```
Through Nimble:
```
nimble install https://github.com/sharpcdf/jitter
```
Manually (versions above 0.3.0):
Download the latest release and run
```
./jtr setup
```
## Uninstalling
Through the install.sh script:
```
wget -qO- https://github.com/sharpcdf/jitter/raw/main/install.sh | bash -s -- --uninstall
```
## Notes
- Right now, Jitter only supports GitHub as a download source.
- You may encounter bugs as this project is still in development, please create an issue if you encounter anything wrong with jitter :)
- On Ubuntu, you may need to run `sudo apt install glibc-source` in order to use jitter.
## Building
Clone the repository and run `nimble build` to create a release version, or `nim debug` to debug the code after making changes.
(You need to have Nim and Nimble installed).
```
git clone https://github.com/sharpcdf/jitter
cd jitter
nimble build
```

## Usage
```
$ jtr
A repository-oriented binary manager for Linux

Usage:
   [options] COMMAND

Commands:

  install          Installs the given repository, if avaliable.                                          [gh:][user/]repo[@tag]
  update           Updates the specified package, Jitter itself, or all packages if specified.           [user/repo[@tag]][all][this|jitter|jtr]
  remove           Removes the specified package from your system.                                       user/repo[@tag]
  search           Searches for repositories that match the given term, returning them if found.         [user/]repo
  list             Lists all executables downloaded.
  catalog          Lists all installed packages.
  setup            Creates needed directories if they do not exist

Options:
  -h, --help
  -v, --version
  --no-make                  If makefiles are found in the downloaded package, Jitter ignores them. By default, Jitter runs all found makefiles.
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
10. ~~`jtr update (this|jitter|jtr)` - updates jitter to the latest release~~ broken in the code revamp, being worked on
11. `jtr update all` - updates all installed packages

Note: repositories are case insensitive, and all AppImage file names are converted to the name of the repository. `jtr install VSCodium/vscodium` is equivalent to `jtr install vscodium/vscodium`.
