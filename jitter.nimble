# Package

version                = "0.4.2-dev"
author                 = "sharpcdf"
description            = "A git-based binary manager for linux."
license                = "MIT"
namedBin["jitter"]     = "jtr"
binDir                 = "bin"
# Dependencies

requires "nim >= 1.6.5"
requires "zippy >= 0.10.3"
requires "argparse >= 3.0.0"

task release, "Build Jitter for release":
  exec "nimble build -d:release -d:version=" & version
