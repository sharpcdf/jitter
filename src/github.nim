import std/[terminal, httpclient, json, strutils, os]
from std/uri import encodeQuery
from std/osproc import execCmdEx
import extract
import parse
let homeDir = getHomeDir() & ".jitter/"
let dDir = homeDir & "nerve/"


var client = newHttpClient(headers=newHttpHeaders([("accept", "application/vnd.github+json")]))
proc downloadRelease(repo: string, make: bool)
#TODO download a specific version
proc download*(repo: var string, version: string, make: bool) =
    #If it has a username, run the code, otherwise searches for the closest matching one
    if repo.contains("/"):
        downloadRelease(repo, make)
    else:
        styledEcho(fgBlue, "Looking for repository " & repo)
        var content = client.getContent("https://api.github.com/search/repositories?" & encodeQuery({"q": repo}))
        var j = parseJson(content)
        var repos = j["items"].getElems()
        var oldRepo = repo
        for r in repos:
            if r["name"].getStr() == repo:
                styledEcho(fgGreen, "Found repository match: " & r["html_url"].getStr() & ", ", fgYellow, "Are you sure you want to install this? [y/N]")
                var i = readLine(stdin)
                if i.toLowerAscii == "n" or i == "" or i.toLowerAscii == "no":
                    styledEcho(fgBlue, "Download denied. Continuing")
                    continue
                elif i.toLowerAscii == "y" or i.toLowerAscii == "yes":
                    repo = r["full_name"].getStr()
                else:
                    styledEcho(fgRed, "Not a valid answer. Exiting")
                    quit()
        if repo == oldRepo:
            styledEcho(fgRed, "No repository match found. Exiting")
            quit()
        downloadRelease(repo, make)
        

proc downloadRelease(repo: string, make: bool) =
        #the owner of the repo
        var user = split(repo, "/")[0]
        #the name of the repo without the user
        var name = split(repo, "/")[1]
        var url = "https://api.github.com/repos/" & repo & "/releases/latest"
        var content = client.getContent(url)
        var j = parseJson(content)
        var assets = j["assets"].getElems()
        #tag, typically version
        var tag = j["tag_name"].getStr()
        #download url
        var dlink: string
        #ext of download file
        var ext: string
        #ditto
        if dirExists(dDir & user & "__" & name & "__" & tag):
            styledEcho(fgRed, "Error: Package " & repo & " " & tag & " is already downloaded. Possibly try 'jtr remove " & repo & "'?")
            quit()
        styledEcho(fgBlue, "Looking for compatible archives")
        #TODO make download specific to cpu type
        for a in assets:
            var n = a["name"].getStr()
            #Checks if asset has extension .tar.gz, .tar.xz, .tgz, is not ARM
            if isCompatibleExt(n) and isCompatibleCPU(n) and isCompatibleOS(n):
                dlink = a["browser_download_url"].getStr()
                if n.endsWith(".tar.gz"):
                    ext = ".tar.gz"
                elif n.endsWith(".tar.xz"):
                    ext = ".tar.xz"
                elif n.endsWith(".tgz"):
                    ext = ".tgz"
                elif n.endsWith(".zip"):
                    ext = ".zip"
                else:
                    continue
                styledEcho(fgGreen, "Archive found: ", fgYellow, styleBlink, n)
                break
        if dlink == "":
            styledEcho(fgRed, "No archives found for ", repo , ", exiting")
            quit()
        styledEcho(fgBlue, "Downloading files from url ", fgYellow, styleBlink, dlink)
        var data = client.getContent(dlink)
        #full path to the tarball
        var dpath = dDir & name & ext
        writeFile(dpath, data)
        styledEcho(fgGreen, "Downloaded ", repo,  fgYellow, " " , tag)
        extract(dpath, user & "__" & name & "__" & tag, make)