import std/[strformat, strutils, osproc, os]

import zippy/tarballs
import zippy/ziparchives

import log, parse

let baseDir = getHomeDir() & ".jitter/"
let nerveDir = baseDir / "nerve"
let binDir = baseDir / "bin"
var dest: string
var dup: bool
proc makeSymlink(file:string, pkg:Package) =
  case file.splitFile().ext:
  of "":
    if not file.hasExecPerms() and file.isExecFile():
      file.setFilePermissions({fpUserExec, fpOthersExec, fpUserRead, fpUserWrite, fpOthersRead, fpOthersWrite})
    if file.hasExecPerms() and file.isExecFile():
      let name = 
        if not dup:
          file.splitFile().name
        else:
          fmt"{file.splitFile().name}@{pkg.tag}"
      try:
        file.createSymlink(binDir / name)
      except:
        error fmt"Failed to create symlink for {file}"
      success fmt"Created symlink {name} from {file}"
  of ".AppImage":
    let name =
      if not dup:
        pkg.repo
      else:
        fmt"{pkg.repo}@{pkg.tag}"
    try:
      file.createSymlink(binDir / name)
    except:
      fatal fmt"Failed to create symlink for {pkg.repo}"
    success fmt"Created symlink {pkg.repo}"

proc walkForExec*(pkg: Package) =
  #Creates symlinks for executables and adds them to the bin
  for file in walkDirRec(nerveDir / dest):
    if ".git" in file:
      continue
    makeSymlink(file, pkg)

proc make*() =
    for path in walkDirRec(nerveDir / dest):
      if path.extractFilename().toLowerAscii() == "makefile":
        info fmt"Attempting to make {path}"
        if (let ex = execCmdEx(fmt"make -C {path.splitFile.dir}"); ex.exitCode != 0):
          error fmt"Failed to make {path}: {ex.output}"
        else:
          success fmt"Successfully made makefile {path}"

proc build*(pkg: Package, dupl = false) =
  dest = pkg.pkgFormat()
  dup = dupl
  var built = false
  for p in walkDir(nerveDir / dest):
    let path = p.path
    #checks if file is a makefile or sh file with build in the name
    if path.extractFilename().toLowerAscii() == "makefile":
      info fmt"Attempting to build package with file {path}..."
      if (let ex = execCmdEx(fmt"make -C {path.splitFile.dir}"); ex.exitCode != 0):
        error fmt"Failed to make {path}: {ex.output}"
      else:
        success fmt"Successfully made makefile {path}"
        built = true
    elif "build" in path.extractFilename().toLowerAscii() and path.splitFile().ext == ".sh":
      info fmt"Attempting to build package with file {path}..."
      if (let ex = execCmdEx(fmt"sh {path}"); ex.exitCode != 0):
        error fmt"Failed to run shell script {path}: {ex.output}"
      else:
        success fmt"Successfully ran shell script {path}"
        built = true
  if not built:
    error "No build files could be made."
    var i = prompt("Would you like to remove the repository?")
    if i:
      removeDir(nerveDir / pkg.pkgFormat().toLowerAscii())
      return
  pkg.walkForExec()

proc extract*(pkg: Package, path, toDir: string, make = true) =
  dest = toDir
  dup = pkg.duplicate()
  ## Extracts `path` inside `toDir` directory.
  info "Extracting files"
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
    make()
  else:
    info "--no-make flag found, skipping make process"
  info "Adding executables to bin"

  walkForExec(pkg)
