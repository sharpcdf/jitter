import std/[strformat, sequtils, strutils, terminal, os]

import argparse

import jitter/[github, parse, log]

#TODO add 'jtr update all' to update all packages
#TODO add config file to manage bin & download directory

const version {.strdefine.} = "undefined"
let baseDir = getHomeDir() & ".jitter/"

proc getInstalledPkgs*(): seq[Package] = 
  for kind, path in walkDir(baseDir / "nerve"):
    if kind == pcDir and (let (ok, pkg) = path.splitPath.tail.parsePkg(); ok):
      result.add(pkg)

proc install(input: string, make = true) = 
  let (srctype, input) = input.parseInputSource()
  let (ok, pkg) = input.parsePkg()

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
  of None:
    fatal "Unknown source type"
    success = false

  if success:
    success "Binaries successfully installed"

proc remove(pkg: Package) = 
  for kind, path in walkDir(baseDir / "bin"):
    if kind == pcLinkToFile and pkg.dirFormat in path.expandSymlink():
      info fmt"Removing symlink {path}"
      path.removeFile()

  removeDir(baseDir / "nerve" / pkg.dirFormat)

proc remove(input: string) = 
  let (ok, pkg) = input.parsePkg()
  if not ok:
    fatal fmt"Couldn't parse package {input}"

  let installedPkgs = getInstalledPkgs()

  if not installedPkgs.anyIt(it.owner == pkg.owner and it.repo == pkg.repo):
    fatal fmt"{input} package is not installed"

  if pkg.tag.len == 0:
    ask "Which tag would you like to remove?"
    for instPkg in installedPkgs:
      if instPkg.owner == pkg.owner and instPkg.repo == pkg.repo:
        list instPkg.gitFormat

    list "All"

    let answer = stdin.readLine().strip()

    if answer.toLowerAscii() == "all":
      for instPkg in installedPkgs:
        if instPkg.owner == pkg.owner and instPkg.repo == pkg.repo:
          instPkg.remove()
    else:
      var valid = false
      for instPkg in installedPkgs:
        if instPkg.owner == pkg.owner and instPkg.repo == pkg.repo and instPkg.tag == answer:
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

  let (ok, pkg) = input.parsePkg()
  if not ok:
    fatal fmt"Couldn't parse package {input}"

  input.remove()
  pkg.ghDownload(make)

  success fmt"Successfully updated {pkg}"

const parser = newParser:
  help("A git-based binary manager for linux.")
  flag("-v", "--version")
  flag("--no-make", help = "If makefiles are found in the downloaded package, Jitter ignores them. By default, Jitter runs all found makefiles.")
  run:
    if opts.version:
      styledEcho(fgCyan, "Jitter version ", fgYellow, NimblePkgVersion)
      styledEcho("For more information visit ", fgGreen, "https://github.com/sharpcdf/jitter")

  command("install"):
    help("Installs the given repository, if avaliable.                                     [gh:][user/]repo[@tag]")
    arg("input")
    flag("nomake")
    run: 
      opts.input.install(not opts.parentOpts.nomake)
  command("update"):
    help("Updates the specified packages, or all packages if none are specified.           user/repo[@tag]")
    arg("input")
    flag("nomake")
    run:
      opts.input.update(not opts.parentOpts.nomake)
  command("remove"):
    help("Removes the specified package from your system.                                  user/repo[@tag]")
    arg("input")
    run:
      opts.input.remove()
  command("search"):
    help("Searches for repositories that match the given term, returning them if found.    [user/]repo")
    arg("query")
    run:
      if opts.query.find(AllChars - IdentChars) >= 0: # If it finds more than IdentChars it should be a package and not a repo
        let (ok, pkg) = opts.query.parsePkg()
        if not ok:
          fatal fmt"Couldn't parse package {opts.query}"

        discard pkg.listPkgGhReleases()
      else:
        discard opts.query.searchGhRepo
  command("list"):
    help("Lists all executables downloaded.")
    run:
      for kind, path in walkDir(baseDir / "bin"):
        if path.hasExecPerms() and path.extractFilename() != "jtr":
          list path
  command("catalog"):
    help("Lists all installed packages.")
    run:
      for pkg in getInstalledPkgs():
        list pkg.gitFormat()

when isMainModule:
  if commandLineParams().len == 0:
    parser.run(@["--help"])
  else:
    parser.run()
