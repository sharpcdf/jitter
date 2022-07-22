import std/[httpclient, strformat, strutils, json, uri, os]

import extract, parse, log

#TODO add support for appimage downloads
#TODO prefer appimages -> .tar.gz -> .tgz -> .zip

let baseDir = getHomeDir() & ".jitter/"
let dDir = baseDir & "nerve/"

proc listPkgGhReleases*(pkg: Package): seq[string] = 
  ## List and return pkg release tags.
  let url = fmt"https://api.github.com/repos/{pkg.owner}/{pkg.repo}/releases"
  let client = newHttpClient()
  var content: string

  try:
    content = client.getContent(url)
  except HttpRequestError:
    fatal "Failed to fetch repository"
  finally:
    client.close()

  let data = content.parseJson()

  if data.kind != JArray:
    fatal fmt"Failed to fetch {pkg.gitFormat} releases"

  info fmt"Listing release tags for {pkg.gitFormat}"

  for release in data.getElems():
    list release["tag_name"].getStr()
    result.add(release["tag_name"].getStr())

proc searchGhRepo*(repo: string): seq[Package] = 
  let url = "https://api.github.com/search/repositories?" & encodeQuery({"q": repo})
  let client = newHttpClient()
  var content: string

  try:
    content = client.getContent(url)
  except HttpRequestError:
    fatal "Failed to fetch repositories"
  finally:
    client.close()

  let data = content.parseJson()
  info &"Found {data[\"total_count\"]} repositories matching the query"

  for repo in data["items"]:
    list &"Github: {repo[\"full_name\"].getStr()}"
    result.add(parsePkg(repo["full_name"].getStr()).pkg)

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
  if dirExists(baseDir / "nerve" / pkg.dirFormat):
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

      success fmt"Archive found: name"
      break

  if downloadUrl.len == 0:
    fatal fmt"No archives found for {pkg.gitFormat}"
      
  info fmt"Downloading {downloadUrl}"

  client.downloadFile(downloadUrl, baseDir / "nerve" / downloadPath)
  success fmt"Downloaded {pkg.gitFormat}"

  extract(baseDir / "nerve" / downloadPath, pkg.dirFormat, make)

proc ghDownload*(pkg: Package, make = true) =
    # If it has a username, run the code, otherwise searches for the closest matching one
    # if pkg.tag.len > 0:
    pkg.downloadRelease(make)
    # else:
    #   let tags = pkg.listPkgGhReleases()
    #   ask "Which tag would you like to download?"
    #   let answer = stdin.readLine().strip()

    #   if answer notin tags:
    #     fatal fmt"Invalid tag {answer}"

    #   package(pkg.owner, pkg.repo, answer).downloadRelease()

proc ghDownload*(repo: string, make = true) = 
  let pkgs = repo.searchGhRepo()
  ask "Which repository would you like to download? (owner/repo)"
  let answer = stdin.readLine().strip()
  let (ok, pkg) = answer.parsePkg()

  if not ok:
    fatal "Couldn't parse package {answer}"

  pkg.ghDownload()
