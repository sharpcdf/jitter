# Jitter
A git-based binary manager for linux

## What is it?
Jitter is a binary manager for linux. It searches github, gitlab, codeberg, and sourcehut for executables that are avaliable to download.


## Building
Note: Building requires the Nim Compiler >= 1.6.6
To build jitter's installer, clone this repository and run `nim installer`. After building, run `./bin/mug` to install jitter.
To develop jitter, git clone the repository and run `nim debug` after making changes.

## Structure
Jitter's source code is separated into two directories. The `mug` directory holds the source code for jitter's installer/updater, mug, while the `src` directory holds the source code for jitter itself.