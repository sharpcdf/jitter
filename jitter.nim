import std/[terminal, os, strutils]
import src/parse
var args: seq[string]
var flags: seq[string]
const version {.strdefine.} = "undefined"
let homeDir = getHomeDir() & ".jitter/"
proc printHelp()
when not declared(commandLineParams):
    styledEcho(fgRed, "Unable to get arguments")
    quit()
else:
    args = commandLineParams()

for f in args:
    if f.startsWith("-"):
        args.add(f)

if (args.len == 1 and args[0] == "help") or args.len == 0:
    printHelp()
    quit()

if args.len >= 1:
    case args[0]:
    of "install":
        if args.len >= 2:
            if parse.install(args[1], true): styledEcho(fgGreen, "Binaries successfully installed")
        else:
            styledEcho(fgRed, "Error: No repo given. Read 'jtr help' for more info")
    of "update":
        echo "filler"
    of "remove":
        if args.len >= 2:
            if not args[1].contains("@"):
                parse.remove(args[1], "")
            else:
                var v = args[1].split("@")[1]
                var r = args[1].split("@")[0]
                parse.remove(r, v)
        else:
            styledEcho(fgRed, "Error: Must provide a package name. Read 'jtr help' for more info")
    of "search":
        echo "filler"
    of "list":
        #TODO be able to list packages in addition to symlink binaries
        for f in walkDir(homeDir & "bin"):
            let file = extractFilename(f.path)
            let perms = getFilePermissions(f.path)
            if f.path == getAppDir() and (fpUserExec in perms or fpGroupExec in perms or fpOthersExec in perms): continue
            styledEcho(fgMagenta, styleItalic, styleUnderscore, file)
    of "version":
        styledEcho(fgCyan, "Jitter version ", fgYellow, version)
        styledEcho("For more information visit ", fgGreen, "https://github.com/sharpcdf/jitter")
        quit()
    else:
        printHelp()
        styledEcho(fgRed, "Error: Unknown command")
        quit()

proc printHelp() =
    echo """Usage:
        jtr <command> [args]

    install [gh:|gl:|cb:|sh:]<[user/]repo>             Installs the binaries of the given repository, if avaliable.
    update <[user/]repo>                               Updates the specified binaries, or all binaries if none are specified.
    remove <user/repo[@version]>                               Removes the specified binaries from your system.
    search [gh:|gl:|cb:|sh:]<[user/]repo>              Searches for binaries that match the given repositories, returning them if found.
    list                                               Lists binaries all binaries downloaded.
    help                                               Prints this help.
    version                                            Prints the version of jitter

    --replace                                          Removes all other binaries with the same name after updating/installing
    --version=<tag>                                    Specifies a version to download                                          
    -ver=<tag>
    --no-make                                          If makefiles are found in the repo, jitter ignores them. By default, jitter runs all found makefiles
    -nm
    """