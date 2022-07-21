import std/[terminal, httpclient, json, strutils, os]
from std/uri import encodeQuery
from std/osproc import execCmdEx
import extract
import parse
import log

#TODO add support for prereleases
let homeDir = getHomeDir() & ".jitter/"
let nerve = homeDir & "nerve/"
var client = newHttpClient(headers=newHttpHeaders([("accept", "application/vnd.github+json")]))
proc downloadRelease(repo, tag: string, make: bool)

#downloads the latest repo release(or the specific tag release if given)
proc download*(repo: var string, tag: string, make: bool) =
    #If it has a username, run the code, otherwise searches for the closest matching one
    if repo.hasRepoFormat():
        downloadRelease(repo, tag, make)
    else:
        info "Looking for repository " & repo
        var content = client.getContent("https://api.github.com/search/repositories?" & encodeQuery({"q": repo}))
        var j = parseJson(content)
        var repos = j["items"].getElems()
        var oldRepo = repo

        for r in repos:
            if r["name"].getStr().toLowerAscii() == repo.toLowerAscii():
                success "Found repository match: " & r["full_name"].getStr()
                ask "Are you sure you want to install this? [y/N]"
                var i = readLine(stdin)

                if i.toLowerAscii == "n" or i == "" or i.toLowerAscii == "no":
                    info "Download denied. Continuing"
                    continue
                elif i.toLowerAscii == "y" or i.toLowerAscii == "yes":
                    repo = r["full_name"].getStr()
                else:
                    fatal "Not a valid answer. Exiting"
        
        if repo == oldRepo:
            fatal "No repository match found. Exiting"
        downloadRelease(repo, tag, make)
        

proc downloadRelease(repo, tag: string, make: bool) =
    #the owner of the repo
    var user = split(repo, "/")[0].toLowerAscii()
    #the name of the repo without the user
    var name = split(repo, "/")[1].toLowerAscii()
    var url: string
    var content: string

    #if tag is given, download the specific one, otherwise download the latest tag
    if tag == "":
        url = "https://api.github.com/repos/" & repo & "/releases/latest"
    else:
        url = "https://api.github.com/repos/" & repo & "/releases/tags/" & tag
    try:
        content = client.getContent(url)
    except HttpRequestError:
        fatal "Release search failed. The repository or tag does not exist."
        
    var j = parseJson(content)
    #sequence of files in the release
    var assets = j["assets"].getElems()
    #tag, typically version
    var tag = j["tag_name"].getStr()
    #download url
    var dlink: string
    #ext of download file
    var ext: string

    #if it already exists then quit and dont download
    if dirExists(nerve & user.toLowerAscii() & "__" & name.toLowerAscii() & "__" & tag):
        fatal "Package " & repo & " " & tag & " is already downloaded. Possibly try 'jtr remove " & repo & "'?"
    info "Looking for compatible archives"
    #TODO make download specific to cpu type
    #looks for asset with compatible cpu, ext and os then sets the file extension for later extraction
    for a in assets:
        var n = a["name"].getStr()
        #Checks if asset has extension .tar.gz, .tar.xz, .tgz, is not ARM
        if isCompatibleExt(n) and isCompatibleCPU(n) and isCompatibleOS(n):
            if n.endsWith(".tar.gz"):
                ext = ".tar.gz"
            elif n.endsWith(".AppImage"):
                ext = ".AppImage"
            elif n.endsWith(".tgz"):
                ext = ".tgz"
            elif n.endsWith(".zip"):
                ext = ".zip"
            else:
                continue
            success "Archive found: " & n
            #optional installation in case the archive isnt compatible with linux
            ask "Do you want to install this archive? There may be more options [Y/n]"
            var i = readLine(stdin)
            if i == "y" or i == "Y" or i == "":
                dlink = a["browser_download_url"].getStr()
            elif i == "n" or i == "no":
                continue
            else:
                error "Unknown answer, downloading anyways"
                dlink = a["browser_download_url"].getStr()
            break
    if dlink == "":
        fatal "No archives found for " & repo & ", exiting"
        
    info "Downloading files from " & dlink
    #downloads files and writes them to reponame.ext then passes it to extract() for extraction
    var data = client.getContent(dlink)
    #full path to the archive or appimage
    var dpath = nerve & name.toLowerAscii() & ext
    writeFile(dpath, data)
    success "Downloaded " & repo & " " & tag
    extract(dpath, user.toLowerAscii() & "__" & name.toLowerAscii() & "__" & tag, make)