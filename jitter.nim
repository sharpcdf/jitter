import std/[sequtils, strutils, terminal, os]

import argparse

import jitter/[begin, log, update]

#TODO add 'jtr update all' to update all packages
#TODO add config file to manage bin & download directory

const version {.strdefine.} = "undefined"
when not defined(version):
  raise newException(ValueError, "Version has to be specified, -d:version=x.y.z")


const parser = newParser:
  help("A repository-oriented binary manager for Linux") ## Help message
  flag("-v", "--version")                                ## Create a version flag
  flag("--no-make", help = "If makefiles are found in the downloaded package, Jitter ignores them. By default, Jitter runs all found makefiles.") ## Create a no-make flag
  flag("--exactmatch", help = "When searching for a repository, only repositories with the query AS THEIR NAME will be shown. Jitter shows any repository returned by the query.")
  flag("-g", help = "Clones the repo, and looks for makefiles or supported file types to build, then adds built executables to the bin.")
  flag("-q", "--quiet", help = "Runs jitter, logging only fatals and errors.")
  flag("--upgrade")
  run:
    log.setQuiet(opts.quiet)
    if opts.version:                                     ## If the version flag was passed
      styledEcho(fgCyan, "Jitter version ", fgYellow, version)
      styledEcho("For more information visit ", fgGreen, "https://github.com/sharpcdf/jitter")

  command("install"):                                    ## Create an install command
    help("Installs the given repository, if avaliable.                                          [gh:][user/]repo[@tag]") ## Help message
    arg("input")                                         ## Positional argument called input
    run:
      opts.input.install(not opts.parentOpts.nomake, opts.parentOpts.g)

  command("update"):                                     ## Create an update command
    help("Updates the specified package, Jitter itself, or all packages if specified.           [user/repo[@tag]][all][this|jitter|jtr]") ## Help message
    arg("input")                                         ## Positional argument called input
    run:
      if opts.input == "upgrade":
        upgrade()
      elif opts.input != "jtr":
        opts.input.update(not opts.parentOpts.nomake)
      else:
        selfUpdate()
  command("remove"):                                     ## Create a remove command
    help("Removes the specified package from your system.                                       user/repo[@tag]") ## Help message
    arg("input")                                         ## Positional arugment called input
    run:
      opts.input.toLowerAscii().remove()
  command("search"):                                     ## Create a search command
    help("Searches for repositories that match the given term, returning them if found.         [user/]repo") ## Help message
    arg("query")                                         ## Positional argument called query
    run:
      opts.query.search(opts.parentOpts.exactmatch)
  command("list"):                                       ## Create a list command
    help("Lists all executables downloaded.")            ## Help message
    run:
      list()
  command("catalog"):                                    ## Create a catalog command
    help("Lists all installed packages.")                ## Help message
    run:
      catalog()
  command("setup"):
    help("Creates needed directories if they do not exist")
    run:
      setup()

when isMainModule:
  if commandLineParams().len == 0:
    parser.run(@["--help"])
  else:
    try:
      if dirExists(getHomeDir() / ".jitter"):
        parser.run()
      else:
        error "Jitter is not installed"
        let yes = prompt("Do you want to install jitter?")
        if yes:
          parser.run(@["setup"])
        else:
          info "Check https://github.com/sharpcdf/jitter for more information on installing jitter."

    except ShortCircuit, UsageError:
      error "Error parsing arguments. Make sure to dot your Ts and cross your Is and try again. Oh, wait."
