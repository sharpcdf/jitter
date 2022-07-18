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
            if parse.install(args[1]): styledEcho(fgGreen, "Binaries successfully installed")
        else:
            styledEcho(fgRed, "Error: Not a valid repo. Read 'jtr help' for more info")
    of "update":
        echo "filler"
    of "remove":
        echo "filler"
    of "search":
        echo "filler"
    of "list":
        for f in walkDir(homeDir & "bin"):
            let file = extractFilename(f.path)
            let perms = getFilePermissions(f.path)
            if f.path == getAppDir() and (fpUserExec in perms or fpGroupExec in perms or fpOthersExec in perms): continue
            styledEcho(fgGreen, styleItalic, styleUnderscore, file)
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
    remove <[user/]repo>                               Removes the specified binaries from your system.
    search [gh:|gl:|cb:|sh:]<[user/]repo>              Searches for binaries that match the given repositories, returning them if found.
    list                                               Lists binaries all binaries downloaded.
    help                                               Prints this help.
    version                                            Prints the version of jitter

    --replace                                          Removes all other binaries with the same name after updating/installing
    --version=<tag>                                    Specifies a version to download                                          
    -ver=<tag>
    """