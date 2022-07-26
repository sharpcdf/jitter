import std/[strformat, strutils, osproc, os]

import zippy/tarballs
import zippy/ziparchives

import log

let baseDir = getHomeDir() & ".jitter/"
let nerveDir = baseDir / "nerve"
let binDir = baseDir / "bin"

proc extract*(path, toDir: string, make = true) =
  ## Extracts `path` inside `toDir` directory.

  info "Extracting files"
  try:
    if path.splitFile().ext == ".zip":
      ziparchives.extractAll(path, nerveDir / toDir)
    else:
      tarballs.extractAll(path, nerveDir / toDir)
  except ZippyError:
    fatal "Failed to extract archive"

  path.removeFile()
  success "Files extracted"

  #if the --no-make flag isnt passed than this happens
  if make:
    for path in walkDirRec(nerveDir / toDir):
      if path.extractFilename().toLowerAscii() == "makefile":
        if execCmdEx(fmt"make -C {path.splitFile.dir}").exitCode != 0:
          fatal fmt"Error: failed to make {path}"

  info "Adding executables to bin"

  #Creates symlinks for executables and adds them to the bin
  for kind, path in walkDir(nerveDir / toDir):
    if kind == pcDir: continue

    let perms = getFilePermissions(path)
    if (fpGroupExec in perms or fpOthersExec in perms or fpUserExec in perms) and path.splitFile.ext == "":
      path.createSymlink(binDir / path.extractFilename())
      success fmt"Created symlink {path.extractFilename()}"
