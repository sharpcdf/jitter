import std/[strformat, strutils, osproc, os]

import zippy/tarballs
import zippy/ziparchives

import log

let baseDir = getHomeDir() & ".jitter/"

proc extract*(path, toDir: string, make = true) =
  ## Extracts `path` inside `toDir` directory.

  info "Extracting files"
  try:
    if path.splitFile().ext == ".zip":
      ziparchives.extractAll(path, baseDir / "nerve" / toDir)
    else:
      tarballs.extractAll(path, baseDir / "nerve" / toDir)
  except ZippyError:
    fatal "Failed to extract archive"

  path.removeFile()
  success "Files extracted"

  #if the --no-make flag isnt passed than this happens
  if make:
    for path in walkDirRec(baseDir / "nerve" / toDir):
      if path.extractFilename().toLowerAscii() == "makefile":
        if execCmdEx(fmt"make -C {path.splitFile.dir}").exitCode != 0:
          fatal fmt"Error: failed to make {path}"

  info "Adding executables to bin"

  #Creates symlinks for executables and adds them to the bin
  for kind, path in walkDir(baseDir / "nerve" / toDir):
    if kind == pcDir: continue

    let perms = getFilePermissions(path)
    if (fpGroupExec in perms or fpOthersExec in perms or fpUserExec in perms) and path.splitFile.ext == "":
      path.createSymlink(baseDir / "bin" & path.extractFilename())
      success fmt"Created symlink {path.extractFilename()}"
