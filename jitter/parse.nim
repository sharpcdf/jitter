import std/[strformat, strutils, strscans, os]

type
  Package* = object
    owner*, repo*, tag*: string

  SourceType* = enum
    Undefined, 
    GitHub,
    GitLab,
    SourceHut,
    CodeBerg

const
  # Supported
  extensions = [".tar.gz", ".tgz", ".zip"]
  # Not supported
  unsupportedCPU = ["arm32", "arm64", "-arm", "arm-"]
  unsupportedOS = ["darwin", "windows", "osx", "macos", "win"]

proc package*(owner, repo, tag: string): Package = 
  return Package(owner: owner, repo: repo, tag: tag)

proc parseInputSource*(input: string): tuple[source: SourceType, output: string] =
  ## Parses the source prefix and returns the (source, input without the preffix).
  result.source = 
    if input.startsWith("gh:"): GitHub
    elif input.startsWith("gl:"): GitLab
    elif input.startsWith("cb:"): CodeBerg
    elif input.startsWith("sh:"): SourceHut
    else: Undefined

  if result.source != Undefined:
    result.output = input[3..^1]
  else:
    result.output = input

proc isCompatibleExt*(file: string): bool =
  result = false
  for ext in extensions:
    if file.endsWith(ext):
      return true

proc isCompatibleCPU*(file: string): bool = 
  result = true
  for cpu in unsupportedCPU:
    if cpu in file:
      return false

proc isCompatibleOS*(file: string): bool =
  result = true
  for os in unsupportedOS:
    if os in file:
      return false

proc hasExecPerms*(file: string): bool =
  let perms = getFilePermissions(file)
  return fpUserExec in perms or fpGroupExec in perms or fpOthersExec in perms

proc validIdent(input: string, strVal: var string, start: int, validChars = IdentChars + {'.', '-'}): int =
  while start + result < input.len and input[start + result] in validChars:
    strVal.add(input[start + result])
    inc result

proc parsePkgFormat*(pkg: string): tuple[ok: bool, pkg: Package] = 
  ## Parses packages in two formats:
  ## - `owner__repo__tag`
  ## - `owner/repo[@tag]` Tag is optional

  var (success, owner, repo, tag) = scanTuple(pkg, "${validIdent()}/${validIdent()}@$+$.", string, string)

  if not success:
    if owner.len > 0 and repo.len > 0 and tag.len == 0: # No tag
      success = true
    else:
      (success, owner, repo, tag) = scanTuple(pkg, "${validIdent()}::${validIdent()}::$+$.", string, string)

  if success:
    result.ok = success
    result.pkg = package(owner, repo, tag)

proc gitFormat*(pkg: Package): string =
  if pkg.owner.len > 0 and pkg.repo.len > 0:
    if pkg.tag.len > 0:
      return fmt"{pkg.owner}/{pkg.repo}@{pkg.tag}"
    else:
      return fmt"{pkg.owner}/{pkg.repo}"

proc pkgFormat*(pkg: Package): string = 
  return fmt"{pkg.owner}::{pkg.owner}::{pkg.tag}"
