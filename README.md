# Jitter
A git-based binary manager for linux

## What is it?
Jitter is a binary manager for linux. It searches github for executables that are avaliable to download. Unlike Homebrew or similar package managers, jitter does not require a brewfile or nixfile in order to recognize the project.


## Building
Note: Building requires the Nim Compiler >= 1.6.6 and Zippy, which you can get by running `nim setup`.
To build jitter's installer, clone this repository, run `nim installer`. After building, run `./bin/mug` to install jitter.
To develop jitter, git clone the repository and run `nim dinstaller` or `nim debug` after making changes.

Warning: both the `debug` and `dinstaller` tasks purely show compiler information at compile time, and are not recommended when building from source as the installer automatically adds jitter to your path.

## Structure
Jitter's source code is separated into two directories. The `mug` directory holds the source code for jitter's installer/updater, mug, while the `src` directory holds the source code for jitter itself.

## Notes
- Jitter is still in development, and there will most likely be bugs. If you encounter an unkown bug, please open an issue :)
- While you are able to download multiple versions of a repository, it will most likely cause conflicts. If this happens, you can simply remove the unneeded package from Jitter.

- Jitter commands are not fully documented yet, but luckily you can look in `jitter.nim` and see the different commands and subcommands that are usable.
- As of right now, Jitter only supports github repositories. New sources may be added with future releases.
- The update command currently does not do anything.
- All listed flags in `jtr help` currently do not work.

## Quick Start
Download the Jitter installer from the releases, and then after navigating to the download directory in your terminal run `./mug install`. This will create all needed directories for downloading and using executables. You can then run `jtr help` after adding it to your path.

### Example Usage
1. `jtr install gh:VSCodium/vscodium` - installs repository VSCodium/vscodium from github.
2. `jtr install vscodium` - searches for all repositories that have the name `vscodium`, and then installs the chosen one
3. `jtr search vscodium` - searches and lists all repositories that have `vscodium` in their name.
4. `jtr search VSCodium/vscodium (tag|tags|true)` - searches and lists all release tags of repository `VSCodium/vscodium`
5. `jtr list` - lists all executables in jitter's bin.
6. `jtr catalog` - lists all downloaded repositories
7. `jtr remove VSCodium/vscodium` - removes VSCodium/vscodium from your system
8. `jtr install VSCodium/vscodium@1.69.0` - installs VSCodium/vscodium release with the tag `1.69.0`
9. `jtr update VSCodium/vscodium` - updates vscodium to the latest version
10. `jtr update (this|jitter|jtr) - updates jitter to the latest release
