import std/[strformat, strutils, strscans, os]

type
  Package* = object
    owner*, repo*, tag*: string

  SourceType* = enum
    None, 
    GitHub,
    GitLab,
    SourceHut,
    CodeBerg

const
  # Supported
  extensions = [".tar.gz", ".tgz", ".zip"]
  # Not supported
  notCpus = ["arm32", "arm64", "-arm", "arm-"]
  notOses = ["darwin", "windows", "osx", "macos", "win"]

proc package*(owner, repo, tag: string): Package = 
  Package(owner: owner, repo: repo, tag: tag)

proc parseInputSource*(input: string): tuple[source: SourceType, output: string] =
  ## Parses the source prefix and returns the (source, input without the preffix).
  result.source = 
    if input.startsWith("gh:"): GitHub
    elif input.startsWith("gl:"): GitLab
    elif input.startsWith("cb:"): CodeBerg
    elif input.startsWith("sh:"): SourceHut
    else: None

  if result.source != None:
    result.output = input[3..^1]
  else:
    result.output = input

proc isCompatibleExt*(path: string): bool =
  path.splitFile.ext in extensions

proc isCompatibleCPU*(path: string): bool = 
  result = true
  for cpu in notCpus:
    if cpu in path:
      return false

proc isCompatibleOS*(path: string): bool =
  result = true
  for os in notOses:
    if os in path:
      return false

proc hasExecPerms*(path: string): bool =
  let perms = getFilePermissions(path)
  result = fpUserExec in perms or fpGroupExec in perms or fpOthersExec in perms

proc parsePkg*(pkg: string): tuple[ok: bool, pkg: Package] = 
  ## Parses packages in two formats:
  ## - `owner__repo__tag`
  ## - `owner/repo[@tag]` Tag is optional

  var (success, owner, repo, tag) = scanTuple(pkg, "$w/$w@$+$.")

  if not success:
    if owner.len > 0 and repo.len > 0 and tag.len == 0: # No tag
      success = true
    else:
      (success, owner, repo, tag) = scanTuple(pkg, "$w__$w__$+$.")

  if success:
    result.ok = success
    result.pkg = package(owner, repo, tag)

proc gitFormat*(pkg: Package): string =
  if pkg.tag.len > 0:
    fmt"{pkg.owner}/{pkg.repo}@{pkg.tag}"
  else:
    fmt"{pkg.owner}/{pkg.repo}"

proc dirFormat*(pkg: Package): string = 
  fmt"{pkg.owner}__{pkg.owner}__{pkg.tag}"
