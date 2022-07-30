import std/[strformat, strutils, osproc, os]

import zippy/tarballs
import zippy/ziparchives

import log, parse

let baseDir = getHomeDir() & ".jitter/"
let nerveDir = baseDir / "nerve"
let binDir = baseDir / "bin"

proc extract*(pkg: Package, path, toDir: string, make = true) =
  ## Extracts `path` inside `toDir` directory.

  info "Extracting files"
  try:
    if path.splitFile().ext == ".zip":
      ziparchives.extractAll(path, nerveDir / toDir)
    elif path.splitFile().ext == ".AppImage":
      createDir(nerveDir / toDir)
      path.setFilePermissions({fpUserExec, fpUserRead, fpUserWrite, fpOthersExec, fpOthersRead, fpOthersWrite, fpGroupExec})
      moveFile(path, nerveDir / toDir / path.extractFilename())
    else:
      tarballs.extractAll(path, nerveDir / toDir)
  except ZippyError:
    fatal "Failed to extract archive"

  path.removeFile()
  success "Files extracted"

  #if the --no-make flag isnt passed than this happens
  if make:
    for path in walkDirRec(nerveDir / toDir):
      if path.extractFilename() .toLowerAscii() == "makefile":
        if execCmdEx(fmt"make -C {path.splitFile.dir}").exitCode != 0:
          error fmt"Error: failed to make {path}"

  info "Adding executables to bin"

  #Creates symlinks for executables and adds them to the bin
  for file in walkDirRec(nerveDir / toDir):
    if file.hasExecPerms() and not symlinkExists(binDir / file.splitFile().name):
      case file.splitFile().ext:
      of "":
        file.createSymlink(binDir / file.splitFile().name)
        success fmt"Created symlink {file.splitFile().name}"
      of ".AppImage":
        file.createSymlink(binDir / pkg.repo)
        success fmt"Created symlink {pkg.repo}"