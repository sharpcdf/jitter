import std/[httpclient, json, strformat, os, osproc]
import log, zippy/tarballs

let baseDir = getHomeDir() / ".jitter"
let binDir = baseDir / "bin"

#* super important to match release asset name (currently jtr.tar.gz) to this
proc selfUpdate*() =
  let url = "https://api.github.com/repos/sharpcdf/jitter/releases/latest"
  let client = newHttpClient(headers = newHttpHeaders([("accept", "application/vnd.github+json")]))
  var content: string
  try:
    content = client.getContent(url)
  except HttpRequestError:
    fatal "Failed to download latest release of Jitter."
  finally:
    client.close()

  let ar = content.parseJson()["assets"][0]["browser_download_url"].getStr()
  echo ar
  try:
    client.downloadFile(ar, binDir)
  except HttpRequestError:
    fatal "Failed to download latest release of Jitter."
  finally:
    client.close()

  try:
    tarballs.extractAll(binDir / "jtr.tar.gz", binDir / "new/")
  except:
    removeFile(binDir / "jtr.tar.gz")
    fatal "Failed to extract"
  removeFile(binDir / "jtr.tar.gz")
  discard startProcess(fmt"./jtr", "{binDir}/jtr/new/", ["update", "upgrade"])

proc upgrade*() =
    if getAppDir().splitPath().tail == "new/":
        removeFile(binDir / "jtr")
        (getAppDir()/getAppFilename()).moveFile(binDir/"jtr")