import std/[terminal, os, strutils]
import src/parse
import src/github as gh
import src/gitlab as gl
import src/sourcehut as sh
import src/codeberg as cb


var args: seq[string]
var flags: seq[string]
const version {.strdefine.} = "undefined"
var baseDir = getHomeDir() & ".jitter/"
proc printHelp()
proc install(src: string, make: bool): bool
proc remove(pkg: string, ver: string)


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
            if install(args[1], true): styledEcho(fgGreen, "Binaries successfully installed")
        else:
            styledEcho(fgRed, "Error: No repo given. Read 'jtr help' for more info")
    of "update":
        echo "filler"
    of "remove":
        if args.len >= 2:
            if not args[1].contains("@"):
                remove(args[1], "")
            else:
                var v = args[1].split("@")[1]
                var r = args[1].split("@")[0]
                remove(r, v)
        else:
            styledEcho(fgRed, "Error: Must provide a package name. Read 'jtr help' for more info")
    of "search":
        echo "filler"
    of "list":
        #TODO be able to list packages in addition to symlink binaries
        for f in walkDir(baseDir & "bin"):
            let file = extractFilename(f.path)
            if f.path == getAppDir() & "jtr" and hasExecPerms(f.path): continue
            styledEcho(fgMagenta, styleItalic, styleUnderscore, file)
    of "version":
        styledEcho(fgCyan, "Jitter version ", fgYellow, version)
        styledEcho("For more information visit ", fgGreen, "https://github.com/sharpcdf/jitter")
        quit()
    of "catalog":
        for d in walkDir(baseDir & "nerve"):
            var owner = d.path.splitPath().tail.split("__")[0]
            var repo = d.path.splitPath().tail.split("__")[1]
            var ver = d.path.splitPath().tail.split("__")[2]
            styledEcho(fgMagenta, styleItalic, styleUnderscore, owner & "/" & repo & "@" & ver)
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
    catalog                                            Lists all installed packages.
    help                                               Prints this help.
    version                                            Prints the version of jitter

    --replace                                          Removes all other binaries with the same name after updating/installing
    --version=<tag>                                    Specifies a version to download                                          
    -ver=<tag>
    --no-make                                          If makefiles are found in the repo, jitter ignores them. By default, jitter runs all found makefiles
    -nm
    """

#TODO maybe add json/toml/whatever file to manage installs more fluidly
#TODO add auto source search, github -> gitlab -> sourcehut -> codeberg
proc install(src: string, make: bool): bool =
    var name = src
    var srctype = parseInputSource(name)
    case srctype:
    of github:
        #* version is temporarily ""
        gh.download(name, "", make)
        return true
    else:
        return false

proc remove(pkg: string, ver: string) =
    if not pkg.contains("/"):
        styledEcho(fgRed, "Error: no repo owner given. Check 'jtr help' for more info")
        quit()
    var user = pkg.split("/")[0]
    var name = pkg.split("/")[1]
    var front = user & "__" & name
    var installed = false
    for p in walkDir(baseDir & "nerve"):
        if p.path.splitPath.tail.contains(name):
            installed = true
    if not installed:
        styledEcho(fgRed, "Error: package " & name & " is not installed.")
        quit()
    if ver == "":
        styledEcho(fgBlue, "What version of " & pkg & " would you like to remove?")
        #prints all packages with the same name
        for p in walkDir(baseDir & "nerve"):
            if p.path.splitPath().tail.startsWith(front):
                styledEcho(fgMagenta, styleItalic, styleUnderscore, p.path.splitPath().tail.split("__")[2])
        var i = readLine(stdin)
        #if package exists, remove all associated symlinks and remove the package directory
        if dirExists(baseDir & "nerve/" & front & "__" & i):
            styledEcho(fgBlue, "Removing " & user & "/" & name & "@" & i)
            var all = front & "__" & i
            var dir = baseDir & "nerve/" & front & "__" & i
            for f in walkDir(baseDir & "bin"):
                if f.kind != pcLinkToFile: continue
                var symp = expandSymlink(f.path)
                if symp.contains(dir):
                    styledEcho(fgCyan, "Removing symlink ", fgYellow, f.path.splitFile().name)
                    f.path.removeFile()
                    continue
            styledEcho(fgCyan, "Removing folder ", fgYellow, baseDir & "nerve/" & all)
            removeDir(baseDir & "nerve/" & front & "__" & i)
            
        else:
            styledEcho(fgRed, "Error: version " & i & " is not installed")
            quit()
    else:
        var all = front & "__" & ver
        styledEcho(fgBlue, "Removing " & user & "/" & name & "@" & ver)
        var dir = baseDir & "nerve/" & all
        for f in walkDir(baseDir & "bin"):
            if f.kind != pcLinkToFile: continue
            var symp = expandSymlink(f.path)
            if symp.contains(dir):
                styledEcho(fgCyan, "Removing symlink ", fgYellow, f.path.splitFile().name)
                f.path.removeFile()
                continue
        styledEcho(fgCyan, "Removing folder ", fgYellow, baseDir & "nerve/" & all)
        removeDir(baseDir & "nerve/" & all)