import std/strutils
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

proc install*(src: string): bool =
    var name = src
    var srctype = parseInputSource(name)
    case srctype:
    of github:
        gh.download(name)
        return true
    else:
        return false