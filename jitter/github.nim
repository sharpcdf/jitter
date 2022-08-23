import std/[httpclient, strformat, strutils, json, uri, os]

import extract, parse, log

#TODO add support for appimage downloads
#TODO prefer appimages -> .tar.gz -> .tgz -> .zip

let baseDir = getHomeDir() & ".jitter/"
let nerveDir = baseDir / "nerve"

proc ghListReleases*(pkg: Package): seq[string] = 
  ## List and return pkg release tags.
  let url = fmt"https://api.github.com/repos/{pkg.owner}/{pkg.repo}/releases"
  let client = newHttpClient()
  var content: string

  try:
    content = client.getContent(url)
  except HttpRequestError:
    fatal "Failed to find repository"
  finally:
    client.close()

  let data = content.parseJson()

  if data.kind != JArray:
    fatal fmt"Failed to find {pkg.gitFormat} releases"

  info fmt"Listing release tags for {pkg.gitFormat}"

  for release in data.getElems():
    list release["tag_name"].getStr()
    result.add(release["tag_name"].getStr())

proc ghSearch*(repo: string, exactmatch: bool = false): seq[Package] = 
  let url = "https://api.github.com/search/repositories?" & encodeQuery({"q": repo})
  let client = newHttpClient()
  var content: string

  try:
    content = client.getContent(url)
  except HttpRequestError:
    fatal "Failed to find repositories"
  finally:
    client.close()

  for r in content.parseJson()["items"]:
    if not exactmatch:
      result.add(parsePkgFormat(r["full_name"].getStr()).pkg)
    else:
      if r["name"].getStr().toLowerAscii() == repo.toLowerAscii():
        result.add(parsePkgFormat(r["full_name"].getStr()).pkg)
      else:
        continue

proc downloadRelease(pkg: Package, make = true) =
  let url = 
    if pkg.tag == "":
      fmt"https://api.github.com/repos/{pkg.owner}/{pkg.repo}/releases/latest"
    else:
      fmt"https://api.github.com/repos/{pkg.owner}/{pkg.repo}/releases/tags/{pkg.tag}"

  let client = newHttpClient(headers = newHttpHeaders([("accept", "application/vnd.github+json")]))
  var content: string

  try:
    content = client.getContent(url)
  except HttpRequestError:
    fatal &"Failed to download {pkg.gitFormat()}."
  finally:
    client.close()

  let data = content.parseJson()
  let pkg = package(pkg.owner, pkg.repo, data["tag_name"].getStr())
  #ditto
  if dirExists(nerveDir / pkg.pkgFormat()):
    fatal fmt"Package {pkg.gitFormat()} already exists."

  info "Looking for compatible archives"
  #TODO make download specific to cpu type

  var downloadUrl, downloadPath: string

  for asset in data["assets"].getElems():
    let name = asset["name"].getStr()
    #Checks if asset has extension .tar.gz, .tar.xz, .tgz, is not ARM
    if name.isCompatibleExt() and name.isCompatibleCPU() and name.isCompatibleOS():
      downloadUrl = asset["browser_download_url"].getStr()
      downloadPath = name

      success fmt"Archive found: {name}"
      ask "Are you sure you want to download this archive? There might be other compatible assets. [Y/n]"
      var answer = stdin.readLine().strip()
      case answer.toLowerAscii():
      of "n", "no":
        continue
      else:
        break

  if downloadUrl.len == 0:
    fatal fmt"No archives found for {pkg.gitFormat()}"
      
  info fmt"Downloading {downloadUrl}"

  client.downloadFile(downloadUrl, getHomeDir() / downloadPath)
  success fmt"Downloaded {pkg.gitFormat()}"

  pkg.extract(nerveDir / downloadPath, pkg.pkgFormat(), make)

proc ghDownload*(pkg: Package, make = true) =
    pkg.downloadRelease(make)

#Downloads repo without owner
proc ghDownload*(repo: string, make = true) = 
  let pkgs = repo.ghSearch(true)
  for pkg in pkgs:
    if pkg.repo.toLowerAscii() == repo.toLowerAscii():
      success fmt"Repository found: {pkg.gitFormat()}"
      ask "Are you sure you want to install this repository? [y/N]"
      let answer = stdin.readLine().strip()
      case answer.toLowerAscii():
      of "y", "yes":
        pkg.ghDownload()
        return
      else:
        continue
  if pkgs.len == 0:
    fatal "No repositories found"
