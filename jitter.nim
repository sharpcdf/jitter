import std/[terminal, os, strutils, httpclient, json]
import src/parse
import src/github as gh
import src/gitlab as gl
import src/sourcehut as sh
import src/codeberg as cb
import src/log
from std/uri import encodeQuery

var args: seq[string]
var flags: seq[string]
const version {.strdefine.} = "undefined"
var baseDir = getHomeDir() & ".jitter/"
proc printHelp()
proc install(src: string, make: bool): bool
proc remove(pkg: string, ver: string)
proc search(repo, ver: string, tags: bool)

when not declared(commandLineParams):
    fatal "Unable to get arguments"
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
        try:
            if install(args[1], true): success "Binaries successfully installed"
        except:
            fatal "No repo given. Read 'jtr help' for more info"
    of "update":
        echo "filler"
    of "remove":
        try:
            #if it contains a tag, pass it to remove()
            if not args[1].contains("@"):
                remove(args[1], "")
            else:
                var s = args[1].split("@")
                remove(s[0], s[1])
        except:
            fatal "Must provide a package name. Read 'jtr help' for more info"
    of "search":
        try:
            if args[2] == "tags" or args[2] == "tag" or args[2] == "true":
                if hasRepoFormat(args[1]):
                    search(args[1], getTagFromGit(args[1]), true)
                else:
                    fatal "Invalid format, must be 'jtr search owner/repo (tags|tag|true)'"
        except:
            search(args[1], getTagFromGit(args[1]), false)
    of "list":
        #TODO add option to list avaliable tags for a repo
        for f in walkDir(baseDir & "bin"):
            let file = extractFilename(f.path)
            if f.path == getAppDir() & "jtr" and hasExecPerms(f.path): continue
            list file
    of "version":
        styledEcho(fgCyan, "Jitter version ", fgYellow, version)
        styledEcho("For more information visit ", fgGreen, "https://github.com/sharpcdf/jitter")
        quit()
    of "catalog":
        for d in walkDir(baseDir & "nerve"):
            list pkgToGitFormat(d.path.splitPath().tail)
    else:
        printHelp()
        fatal "Unknown command"

proc printHelp() =
    echo """Usage:
        jtr <command> [args]

    install [gh:|gl:|cb:|sh:]<[user/]repo[@tag]>       Installs the binaries of the given repository, if avaliable.
    update <user/repo>                                 Updates the specified binaries, or all binaries if none are specified.
    remove <user/repo[@version]>                       Removes the specified binaries from your system.
    search <[user/]repo> [tags|tag|true]                                      Searches for binaries that match the given repositories, returning them if found.
    list                                               Lists all executables downloaded.
    catalog                                            Lists all installed packages.
    help                                               Prints this help.
    version                                            Prints the version of jitter

    --replace                                          Removes all other binaries with the same name after updating/installing
    --version=<tag>                                    Specifies a version to download                                          
    -ver=<tag>
    --no-make                                          If makefiles are found in the repo, jitter ignores them. By default, jitter runs all found makefiles
    -nm
    --exact-match                                      Only searches for repos that exactly match the search term
    """

#* auto source search, github -> gitlab -> sourcehut -> codeberg
proc install(src: string, make: bool): bool =
    var name = src
    var srctype = parseInputSource(name)
    var tag = name.getTagFromGit()
    case srctype:
    of github:
        #* version is temporarily ""
        gh.download(name, tag, make)
        return true
    of undefined:
        gh.download(name, tag, make)
        #gl.download(name, tag, make)
        #sh.download(name, tag, make)
        #cb.download(name, tag, make)
    else:
        return false

proc remove(pkg: string, ver: string) =
    if not pkg.hasRepoFormat():
        fatal "Invalid format given. Check 'jtr help' for more info"
    var user = pkg.split("/")[0]
    var name = pkg.split("/")[1]
    var front = user & "__" & name
    var installed = false
    for p in walkDir(baseDir & "nerve"):
        if p.path.splitPath.tail.contains(name):
            installed = true
    if not installed:
        fatal "package " & name & " is not installed."
    if ver == "":
        ask "What tag of " & pkg & " would you like to remove?"
        #prints all packages with the same name
        for p in walkDir(baseDir & "nerve"):
            if p.path.splitPath().tail.startsWith(front):
                list p.path.splitPath().tail.split("__")[2]
        list "all"
        var i = readLine(stdin)
        #if package exists, remove all associated symlinks and remove the package directory
        if dirExists(baseDir & "nerve/" & front & "__" & i):
            var all = front & "__" & i
            info "Removing " & pkgToGitFormat(all)
            var dir = baseDir & "nerve/" & all
            for f in walkDir(baseDir & "bin"):
                if f.kind != pcLinkToFile: continue
                var symp = expandSymlink(f.path)
                if symp.contains(dir):
                    info "Removing symlink " & f.path.splitFile().name
                    f.path.removeFile()
                    continue
            info "Removing folder " & dir
            removeDir(baseDir & "nerve/" & front & "__" & i)
        elif i.toLowerAscii() == "all":
            info "Removing all versions of " & pkg
            for f in walkDir(baseDir & "bin"):
                if f.kind != pcLinkToFile: continue
                var symp = expandSymlink(f.path)
                if front in symp:
                    info "Removing symlink " & f.path.splitFile().name
                    f.path.removeFile()
                    continue
            for f in walkDir(baseDir & "nerve"):
                if front in f.path:
                    info "Removing folder " & f.path.splitPath().tail
                    removeDir(f.path)
        else:
            fatal "tag " & i & " is not installed"
        success "Done"
    else:
        var all = front & "__" & ver
        info "Removing " & pkgToGitFormat(all)
        var dir = baseDir & "nerve/" & all
        for f in walkDir(baseDir & "bin"):
            if f.kind != pcLinkToFile: continue
            var symp = expandSymlink(f.path)
            if symp.contains(dir):
                info "Removing symlink " & f.path.splitFile().name
                f.path.removeFile()
                continue
        info "Removing folder " & dir
        removeDir(baseDir & "nerve/" & all)

#TODO add rest of the sources to search
proc search(repo, ver: string, tags: bool) =
    var c = newHttpClient()
    if not tags:
        var ghurl = "https://api.github.com/search/repositories?" & encodeQuery({"q": repo})
        var content: string
        try:
            content = c.getContent(ghurl)
        except HttpRequestError:
            fatal "Failed to get repositories"
        var j = content.parseJson()["items"].getElems()
        for e in j:
            list "Github: " & e["full_name"].getStr()
    else:
        var ghurl = "https://api.github.com/repos/" & repo & "/releases"
        var content: string
        try:
            content = c.getContent(ghurl)
        except HttpRequestError:
            fatal "Failed to get repository tags. Repository does not exist."
        var j = content.parseJson().getElems()
        info "Listing release tags for " & repo
        for e in j:
            list e["tag_name"].getStr()

