import std/[strutils, os, terminal]
import gitlab as gl
import github as gh
import codeberg  as cb
import sourcehut as sh


type SourceType = enum
    github,
    gitlab,
    sourcehut,
    codeberg,
    undefined
var baseDir = getHomeDir() & ".jitter/"

##Parses the source prefix, returning the source type and removing the prefix
proc parseInputSource*(url: var string): SourceType =
    if url.startsWith("gh:"):
        url.removePrefix("gh:")
        return github
    elif url.startsWith("gl:"):
        url.removePrefix("gl:")
        return gitlab
    elif url.startsWith("cb:"):
        url.removePrefix("cb:")
        return codeberg
    elif url.startsWith("sh:"):
        url.removePrefix("sh:")
        return sourcehut
    else:
        return undefined
#TODO maybe add json/toml/whatevre file to manage installs more fluidly
proc install*(src: string, make: bool): bool =
    var name = src
    var srctype = parseInputSource(name)
    case srctype:
    of github:
        #* version is temporarily ""
        gh.download(name, "", make)
        return true
    else:
        return false

proc remove*(pkg: string, ver: string) =
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

