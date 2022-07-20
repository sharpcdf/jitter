import std/[strutils, os, terminal]


type SourceType* = enum
    github,
    gitlab,
    sourcehut,
    codeberg,
    undefined
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

proc isCompatibleExt*(file: string): bool =
    result = false
    const ext = [".tar.gz", ".tgz", ".zip"]
    for s in ext:
        if file.endsWith(s):
            return true

proc isCompatibleCPU*(file: string): bool = 
    result = true
    const cpu = ["arm32", "arm64", "-arm", "arm-"]
    for s in cpu:
        if s in file:
            return false

proc isCompatibleOS*(file: string): bool =
    result = true
    const os = ["darwin", "windows", "osx", "macos", "win"]
    for s in os:
        if s in file:
            return false

proc hasExecPerms*(file: string): bool =
    var perms = getFilePermissions(file)
    if fpUserExec in perms or fpGroupExec in perms or fpOthersExec in perms:
        return true
    else:
        return false

#pass folder name owner__repo__tag and return owner/repo@tag
proc pkgToGitFormat*(name: string): string =
    var u = name.split("__")[0]
    var r = name.split("__")[1]
    var v = name.split("__")[2]
    return u & "/" & r & "@" & v

#gets tag from owner__repo__tag
proc getTagFromPackageName*(name: string): string =
    return name.split("__")[2]

#gets tag from owner/repo@tag
proc getTagFromGit*(name: var string): string =
    try:
        var t = name.split("@")
        if t.len == 2:
            name = t[0]
            return t[1]
        else:
            return ""
    except:
        return ""

proc hasRepoFormat*(name: string): bool =
    if "/" in name:
        if not name.startsWith("/") and not name.endsWith("/"):
            return true
    return false