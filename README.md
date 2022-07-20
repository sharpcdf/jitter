# Jitter
A git-based binary manager for linux

## What is it?
Jitter is a binary manager for linux. It searches github, gitlab, codeberg, and sourcehut for executables that are avaliable to download.


## Building
Note: Building requires the Nim Compiler >= 1.6.6 and Zippy, which you can get by running `nim setup`
To build jitter's installer, clone this repository and run `nim installer`. After building, run `./bin/mug` to install jitter.
To develop jitter, git clone the repository and run `nim dinstaller` or `nim debug` after making changes.

Warning: both the `debug` and `dinstaller` tasks purely show compiler information at compile time, and are not recommended when building from source as the installer automatically adds jitter to your path.

## Structure
Jitter's source code is separated into two directories. The `mug` directory holds the source code for jitter's installer/updater, mug, while the `src` directory holds the source code for jitter itself.

## Notes
- Jitter is still in development, and there will most likely be bugs. If you encounter an unkown bug, please open an issue :)
- While you are able to download multiple versions of a repository, it will most likely cause conflicts and errors. If this happens, you can simply remove the unneeded package from Jitter.
- Jitter commands are not fully documented yet, but luckily you can look in `jitter.nim` and see the different commands and subcommands that are usable.
- As of right now, Jitter only supports github repositories. A new search source will be added with every new release of the installer.
- The update command currently does not do anything.
- All listed flags in `jtr help` currently do not work.

## Quick Start
Download the Jitter installer from the releases, and then after navigating to the download directory in your terminal run `./mug install`. This will create all needed directories for downloading and using executables. You can then run `jtr help` after adding it to your path.

### Example Usage
`jtr install gh:VSCodium/vscodium` - installs repository VSCodium/vscodium from github.
`jtr install vscodium` - searches for all repositories that have the name `vscodium`, and then installs the chosen one
`jtr search vscodium` - searches and lists all repositories that have `vscodium` in their name.
`jtr search VSCodium/vscodium (tag|tags|true)` - searches and lists all release tags of repository `VSCodium/vscodium`
`jtr list` - lists all executables in jitter's bin.
`jtr catalog` - lists all downloaded repositories
`jtr remove VSCodium/vscodium` - removes VSCodium/vscodium from your system
`jtr install VSCodium/vscodium@1.69.0` - installs VSCodium/vscodium release with the tag `1.69.0`