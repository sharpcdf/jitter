import std/[strformat, strutils, osproc, os]

import zippy/tarballs
import zippy/ziparchives

import log, parse

let baseDir = getHomeDir() & ".jitter/"
let nerveDir = baseDir / "nerve"
let binDir = baseDir / "bin"
var duplicate = false
proc makeSymlink(file:string, pkg:Package)

proc extract*(pkg: Package, path, toDir: string, make = true) =
  ## Extracts `path` inside `toDir` directory.

  info "Extracting files"
  for p in walkDir(nerveDir):
    if pkg.repo in p.path and pkg.owner in p.path:
      duplicate = true
      break
  try:
    #toDir should be called a package version of the repo name, in nerve directory
    #path is downloadPath in github.nim
    if path.splitFile().ext == ".zip":
      ziparchives.extractAll(path, nerveDir / toDir)
    elif path.splitFile().ext == ".AppImage":
      createDir(nerveDir / toDir)
      path.setFilePermissions({fpUserExec, fpUserRead, fpUserWrite, fpOthersExec, fpOthersRead, fpOthersWrite, fpGroupExec})
      moveFile(path, nerveDir / toDir / path.extractFilename())
    else:
      tarballs.extractAll(path, nerveDir / toDir)
  except ZippyError:
    for f in walkDir(nerveDir):
      if f.path == path:
        removeFile(path)
        break
    fatal "Failed to extract archive [ZippyError]"
  except IOError:
    for f in walkDir(nerveDir):
      if f.path == path:
        removeFile(path)
        break
    fatal "Failed to extract archive [IOError]"

  path.removeFile()
  success "Files extracted"

  #if the --no-make flag isnt passed than this happens
  if make:
    for path in walkDirRec(nerveDir / toDir):
      if path.extractFilename() .toLowerAscii() == "makefile":
        info fmt"Attempting to make {path}"
        if execCmdEx(fmt"make -C {path.splitFile.dir}").exitCode != 0:
          error fmt"Error: failed to make {path}"
        else:
          success fmt"Successfully made makefile {path}"
  else:
    info "--no-make flag found, skipping make process"

  info "Adding executables to bin"

  #Creates symlinks for executables and adds them to the bin
  for file in walkDirRec(nerveDir / toDir):
    if not duplicate:
      if not symlinkExists(binDir / file.splitFile().name):
        makeSymlink(file, pkg)
    else:
      if not symlinkExists(binDir / fmt"{file.splitFile().name}-{pkg.tag}"):
        makeSymlink(file, pkg)

proc makeSymlink(file:string, pkg:Package) =
  case file.splitFile().ext:
  of "":
    if not file.hasExecPerms() and file.splitFile().name.isExecFile():
      file.setFilePermissions({fpUserExec, fpOthersExec, fpUserRead, fpUserWrite, fpOthersRead, fpOthersWrite})
    if file.hasExecPerms() and file.splitFile().name.isExecFile():
      var name: string
      try:
        if not duplicate:
          name = file.splitFile().name
        else:
          name = fmt"{file.splitFile().name}@{pkg.tag}"
        file.createSymlink(binDir / name)
      except:
        error fmt"Failed to create symlink for {file}"
      success fmt"Created symlink {name}"
  of ".AppImage":
    var name: string
    try:
      if not duplicate:
        name = pkg.repo
      else:
        name = fmt"{pkg.repo}@{pkg.tag}"
      file.createSymlink(binDir / name)
    except:
      fatal fmt"Failed to create symlink for {pkg.repo}"
    success fmt"Created symlink {pkg.repo}"