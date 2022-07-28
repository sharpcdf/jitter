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

proc ghSearch*(repo: string): seq[Package] = 
  let url = "https://api.github.com/search/repositories?" & encodeQuery({"q": repo})
  let client = newHttpClient()
  var content: string

  try:
    content = client.getContent(url)
  except HttpRequestError:
    fatal "Failed to find repositories"
  finally:
    client.close()

  for repo in content.parseJson()["items"]:
    result.add(parsePkgFormat(repo["full_name"].getStr()).pkg)

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
    fatal &"Failed to download {pkg.gitFormat}."
  finally:
    client.close()

  let data = content.parseJson()
  let pkg = package(pkg.owner, pkg.repo, data["tag_name"].getStr())
  #ditto
  if dirExists(nerveDir / pkg.pkgFormat):
    fatal fmt"Package {pkg.gitFormat} already exists."

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
      ask "Are you sure you want to download this archive? There might be other compatible assets. [y/N]"
      var answer = readLine(stdin)
      if answer.toLowerAscii() == "n" or answer.toLowerAscii() == "no":
        continue
      elif answer.toLowerAscii() == "y" or answer.toLowerAscii() == "yes" or answer == "":
        break
      else:
        fatal "Invalid answer, exiting"

  if downloadUrl.len == 0:
    fatal fmt"No archives found for {pkg.gitFormat()}"
      
  info fmt"Downloading {downloadUrl}"

  client.downloadFile(downloadUrl, nerveDir / downloadPath)
  success fmt"Downloaded {pkg.gitFormat()}"

  pkg.extract(nerveDir / downloadPath, pkg.pkgFormat(), make)

proc ghDownload*(pkg: Package, make = true) =
    # If it has a username, run the code, otherwise searches for the closest matching one
    # if pkg.tag.len > 0:
    pkg.downloadRelease(make)
    # else:
    #   let tags = pkg.ghListReleases()
    #   ask "Which tag would you like to download?"
    #   let answer = stdin.readLine().strip()

    #   if answer notin tags:
    #     fatal fmt"Invalid tag {answer}"

    #   package(pkg.owner, pkg.repo, answer).downloadRelease()

proc ghDownload*(repo: string, make = true) = 
  let pkgs = repo.ghSearch()
  for pkg in pkgs:
    if pkg.gitFormat().toLowerAscii() == repo.toLowerAscii():
      list pkg.gitFormat()
  ask "Which repository would you like to download? (owner/repo)"
  let answer = stdin.readLine().strip()
  let (ok, pkg) = answer.parsePkgFormat()

  if not ok:
    fatal "Couldn't parse package {answer}"

  pkg.ghDownload()
