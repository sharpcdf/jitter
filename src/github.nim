import std/[terminal, httpclient, json, strutils, os]

let homeDir = getHomeDir() & ".jitter/"

proc download*(repo: string) =
    var name = split(repo, "/")[1]
    var client = newHttpClient(headers=newHttpHeaders([("accept", "application/vnd.github+json")]))
    var uri = "https://api.github.com/repos/" & repo & "/releases/latest"
    var content = client.getContent(uri)
    var j = parseJson(content)
    var assets = j["assets"].getElems()
    var url = j["html_url"].getStr()
    var tag = j["tag_name"].getStr()
    var dlink: string
    styledEcho(fgBlue, "Looking for tarball")
    for a in assets:
        var name = a["name"].getStr()
        if name.endsWith(".tar.gz") or name.endsWith("tar.xz")  or name.endsWith("tgz") and not name.contains("amd"): #TODO Check to see if there's a more efficient way tomorrow
            dlink = a["browser_download_url"].getStr()
            break
    if dlink == "":
        styledEcho(fgRed, "No tarballs found for ", repo , ", exiting")
        quit()
    styledEcho(fgGreen, "Downloading binaries from url ", dlink)
    var data = client.getContent(dlink)
    writeFile(homeDir & "nerve/" & name & ".tar" & splitFile(dlink).ext, data) #*temp .tar string addition, change later
    styledEcho(fgGreen, "Downloaded ", repo,  fgYellow, " " , tag)