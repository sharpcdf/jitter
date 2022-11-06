import std/[strformat, sequtils, strutils, terminal, os]
import parse, github, log

let baseDir = getHomeDir() / ".jitter"
let nerveDir = baseDir / "nerve"
let binDir = baseDir / "bin"

proc getInstalledPkgs*(): seq[Package] =
  for kind, path in walkDir(nerveDir):
    if kind == pcDir and (let (ok, pkg) = path.splitPath.tail.parsePkgFormat(); ok):
      result.add(pkg)

proc search*(query: string, exactmatch = false) =
  if '/' in query:
    let (ok, pkg) = query.parsePkgFormat()
    if not ok:
      fatal fmt"Couldn't parse package {query}"

    discard pkg.ghListReleases()
  else:
    for pkg in query.ghSearch(exactmatch):
      list &"Github: {pkg.gitFormat()}"

proc setup*() =
  if dirExists(getHomeDir() / ".jitter"):
    fatal "Jitter is already set up!"
  info "Creating directories"
  createDir(getHomeDir() / ".jitter")
  createDir(getHomeDir() / ".jitter/bin")
  createDir(getHomeDir() / ".jitter/nerve")
  createDir(getHomeDir() / ".jitter/config")
  success "Done!"
  let yes = prompt(&"Do you want to add {getAppDir()} to your path?")
  if yes:
    if &"export PATH=$PATH:{getAppDir()}" in readFile(getHomeDir() / ".bashrc"):
      error "Jitter is already in your .bashrc file!"
    else:
      let f = open(getHomeDir() / ".bashrc", fmAppend)
      f.writeLine(&"export PATH=$PATH:{getAppDir()}")
      f.close()
      success "Added to bash path!"
    if getEnv("SHELL") == "/usr/bin/fish":
      info "Adding jitter to fish user paths via config.fish file"
      if &"set -U fish_user_paths $fish_user_paths {getAppDir()}" in readFile(
          &"{getHomeDir()}.config/fish/config.fish"):
        error "Jitter is already in your config.fish file!"
      else:
        let f = open(getHomeDir() / ".config/fish/config.fish", fmAppend)
        f.writeLine(&"set -U fish_user_paths $fish_user_paths {getAppDir()}")
        f.close()
        success "Added to fish path!"
  else:
    info &"Consider running 'echo \"export PATH=$PATH:{getAppDir()}\" >> {getHomeDir()}.bashrc' to add it to your bash path."


proc install*(input: string, make = true, build = false) =
  let (srctype, input) = input.parseInputSource()
  if '/' notin input:
    info fmt"Searching for {input}"
    input.ghDownload(make, build)
    return

  let (ok, pkg) = input.parsePkgFormat()

  if not ok:
    fatal fmt"Couldn't parse package {input}"

  var success = true
  case srctype:
  of GitHub:
    pkg.ghDownload(make, build)
  of GitLab:
    #pkg.glDownload(make)
    discard
  of SourceHut:
    # pkg.shDownload(make)
    discard
  of CodeBerg:
    #pkg.cbDownload(make)
    discard
  of Undefined:
    
    pkg.ghDownload(make, build)
    #pkg.glDownload(make)
    #pkg.cbDownload(make)
    #pkg.shDownload(make)

  if success:
    success "Binaries successfully installed"

proc remove*(pkg: Package) =
  for kind, path in walkDir(binDir):
    if kind == pcLinkToFile and pkg.pkgFormat() in path.expandSymlink():
      info fmt"Removing symlink {path}"
      path.removeFile()

  removeDir(nerveDir / pkg.pkgFormat().toLowerAscii())

proc remove*(input: string) =
  let (ok, pkg) = input.parsePkgFormat()
  if not ok:
    fatal fmt"Couldn't parse package {input}"

  let installedPkgs = getInstalledPkgs()

  if not installedPkgs.anyIt(it.owner == pkg.owner and it.repo == pkg.repo):
    fatal fmt"{input} package is not installed"

  if pkg.tag.len == 0:
    ask "Which tag would you like to remove?"
    #goes through all installed package versions and lists them
    for instPkg in installedPkgs:
      if instPkg.owner == pkg.owner and instPkg.repo == pkg.repo:
        list instPkg.tag
    #lists the option to remove all versions
    list "All"

    let answer = stdin.readLine().strip()
    case answer.toLowerAscii():
    of "all":
      for instPkg in installedPkgs:
        if instPkg.owner == pkg.owner and instPkg.repo == pkg.repo:
          instPkg.remove()
    else:
      var valid = false
      for instPkg in installedPkgs:
        if instPkg.tag == answer:
          valid = true
      if not valid:
        fatal "Invalid tag"
      else:
        package(pkg.owner, pkg.repo, answer).remove()
  else:
    pkg.remove()

  success "Done"

proc selfUpdate*() =
  ghDownload(parsePkgFormat("sharpcdf/jitter").pkg, true)
  var downloaded = false
  var pkg: string
  for p in getInstalledPkgs():
    if p.owner == "sharpcdf" and p.repo == "jitter":
      downloaded = true
      pkg = p.pkgFormat()
      break
  if not downloaded:
    fatal "Failed to update Jitter to latest version"
  copyFile(nerveDir / pkg, getAppDir() / getAppFilename())
  success "Successfully updated Jitter to the latest version!"

proc update*(input: string, make = true) =
  if input.toLowerAscii() in ["this", "jtr", "jitter"]:
    selfUpdate()
    return
  if input.toLowerAscii() == "all":
    for pkg in getInstalledPkgs():
      pkg.remove()
      pkg.ghDownload(make)
    return
  let (ok, pkg) = input.parsePkgFormat()
  if not ok:
    fatal fmt"Couldn't parse package {input}"

  input.remove()
  pkg.ghDownload(make)

  success fmt"Successfully updated {pkg.owner}/{pkg.repo}"

proc list*() =
  for kind, path in walkDir(binDir):
    if path.hasExecPerms() and path.extractFilename() != "jtr":
      list path.extractFilename()

proc catalog*() =
  for pkg in getInstalledPkgs():
    list pkg.gitFormat()
