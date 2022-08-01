import std/[strformat, sequtils, strutils, terminal, os]

import argparse

import jitter/[github, parse, log]

#TODO add 'jtr update all' to update all packages
#TODO add config file to manage bin & download directory

const version {.strdefine.} = "undefined"
when not defined(version):
  raise newException(ValueError, "Version has to be specified -d:version=x.y.z")

let baseDir = getHomeDir() / ".jitter"
let nerveDir = baseDir / "nerve"
let binDir = baseDir / "bin"

proc getInstalledPkgs*(): seq[Package] = 
  for kind, path in walkDir(nerveDir):
    if kind == pcDir and (let (ok, pkg) = path.splitPath.tail.parsePkgFormat(); ok):
      result.add(pkg)

proc search(query: string) = 
  if '/' in query: 
    let (ok, pkg) = query.parsePkgFormat()
    if not ok:
      fatal fmt"Couldn't parse package {query}"

    discard pkg.ghListReleases()
  else:
    for pkg in query.ghSearch():
      list &"Github: {pkg.gitFormat()}"

proc install(input: string, make = true) = 
  let (srctype, input) = input.parseInputSource()
  if '/' notin input:
    info fmt"Searching for {input}"
    input.ghDownload(make)
    return

  let (ok, pkg) = input.parsePkgFormat()

  if not ok:
    fatal fmt"Couldn't parse package {input}"

  var success = true
  case srctype:
  of GitHub:
    pkg.ghDownload(make)
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
    pkg.ghDownload(make)
    #pkg.glDownload(make)
    #pkg.cbDownload(make)
    #pkg.shDownload(make)

  if success:
    success "Binaries successfully installed"

proc remove(pkg: Package) = 
  for kind, path in walkDir(binDir):
    if kind == pcLinkToFile and pkg.pkgFormat() in path.expandSymlink():
      info fmt"Removing symlink {path}"
      path.removeFile()

  removeDir(nerveDir / pkg.pkgFormat().toLowerAscii())

proc remove(input: string) = 
  let (ok, pkg) = input.parsePkgFormat()
  if not ok:
    fatal fmt"Couldn't parse package {input}"

  let installedPkgs = getInstalledPkgs()

  if not installedPkgs.anyIt(it.owner == pkg.owner and it.repo == pkg.repo):
    fatal fmt"{input} package is not installed"

  if pkg.tag.len == 0:
    ask "Which tag would you like to remove?"
    for instPkg in installedPkgs:
      if instPkg.owner == pkg.owner and instPkg.repo == pkg.repo:
        list instPkg.tag

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

proc update(input: string, make = true) = 
  let input = 
    if input.toLowerAscii() in ["this", "jtr", "jitter"]:
      "sharpcdf/jitter"
    else:
      input
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

  success fmt"Successfully updated {pkg}"

proc list() = 
  for kind, path in walkDir(binDir):
    if path.hasExecPerms() and path.extractFilename() != "jtr":
      list path.extractFilename()

proc catalog() = 
  for pkg in getInstalledPkgs():
    list pkg.gitFormat()

const parser = newParser:
  help("A git-based binary manager for Linux") ## Help message
  flag("-v", "--version") ## Create a version flag
  flag("--no-make", help = "If makefiles are found in the downloaded package, Jitter ignores them. By default, Jitter runs all found makefiles.") ## Create a no-make flag
  run:
    if opts.version: ## If the version flag was passed
      styledEcho(fgCyan, "Jitter version ", fgYellow, version)
      styledEcho("For more information visit ", fgGreen, "https://github.com/sharpcdf/jitter")

  command("install"): ## Create an install command
    help("Installs the given repository, if avaliable.                                          [gh:][user/]repo[@tag]") ## Help message
    arg("input") ## Positional argument called input
    run: 
      opts.input.install(not opts.parentOpts.nomake)
  command("update"): ## Create an update command
    help("Updates the specified packages, or all packages if none are specified.           user/repo[@tag]") ## Help message
    arg("input") ## Positional argument called input
    run:
      opts.input.update(not opts.parentOpts.nomake)
  command("remove"): ## Create a remove command
    help("Removes the specified package from your system.                                       user/repo[@tag]") ## Help message
    arg("input") ## Positional arugment called input
    run:
      opts.input.toLowerAscii().remove()
  command("search"): ## Create a search command
    help("Searches for repositories that match the given term, returning them if found.         [user/]repo") ## Help message
    arg("query") ## Positional argument called query
    run:
      opts.query.search()
  command("list"): ## Create a list command
    help("Lists all executables downloaded.") ## Help message
    run:
      list()
  command("catalog"): ## Create a catalog command
    help("Lists all installed packages.") ## Help message
    run:
      catalog()
when isMainModule:
  if commandLineParams().len == 0:
    parser.run(@["--help"])
  else:
    try:
      if dirExists(getHomeDir() / ".jitter"):
        parser.run()
      else:
        fatal "Jitter is not installed, check https://github.com/sharpcdf/jitter to install it"
    except ShortCircuit:
      error "Error parsing arguments. Make sure to dot your Ts and cross your Is and try again. Oh, wait."
      raise
