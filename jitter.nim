import std/[terminal, os]
include src/help

var args: seq[string]
const version {.strdefine.} = "undefined"
let homeDir = getHomeDir() & ".jitter/"
when not declared(commandLineParams):
    styledEcho(fgRed, "Unable to get arguments")
    quit()
else:
    args = commandLineParams()

if (args.len == 1 and args[0] == "help") or args.len == 0:
    printHelp()
    quit()

if args.len >= 1:
    case args[0]:
    of "install":
        echo "filler"
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
