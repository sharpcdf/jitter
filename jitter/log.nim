import std/[terminal, strformat, strutils]

var quiet: bool

proc info*(s: string) =
  if not quiet:
    styledEcho({styleBright}, fgCyan, "[I]", resetStyle, " ", fgBlue, styleUnderscore, s)

proc fatal*(s: string) =
  styledEcho({styleBright}, fgRed, "[F]", resetStyle, " ", fgRed, styleUnderscore, s)
  quit(1)

proc success*(s: string) =
  if not quiet:
    styledEcho({styleBright}, fgGreen, "[S]", resetStyle, " ", fgGreen, styleItalic, s)

proc list*(s: string) =
  styledEcho({styleBright, styleItalic}, fgMagenta, s)

proc ask*(s: string) =
  styledEcho({styleBright}, fgBlue, "[Q]", resetStyle, " ", fgYellow, s)

proc error*(s: string) =
  styledEcho({styleBright}, fgRed, "[E]", resetStyle, " ", fgRed, s)

proc prompt*(question: string): bool =
  ask fmt"{question} [y/n]"
  let r = stdin.readLine().strip()
  case r.toLowerAscii():
  of "n", "no":
    return false
  of "y", "yes":
    return true
  else:
    error "Invalid answer given."
    prompt(question)

proc setQuiet*(q: bool) =
  if q:
    quiet = true
  else:
    quiet = false