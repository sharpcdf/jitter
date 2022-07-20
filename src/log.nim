import std/terminal

proc info*(s: string) =
    styledEcho({styleBlink, styleBright}, fgCyan, "[I]", resetStyle, " ", fgBlue, styleUnderscore, s)

proc fatal*(s: string) =
    styledEcho({styleBlink, styleBright}, fgRed, "[F]", resetStyle, " ", fgRed, styleUnderscore, s)
    quit()

proc success*(s: string) =
    styledEcho({styleBlink, styleBright}, fgGreen, "[S]", resetStyle, " ", fgGreen, styleItalic, s)

proc list*(s: string) =
    styledEcho({styleBlink, styleBright, styleItalic}, fgMagenta, s)

proc ask*(s: string) =
    styledEcho({styleBlink, styleBright}, fgBlue, "[Q]", resetStyle, " ", fgYellow, s)

proc error*(s: string) =
    styledEcho({styleBlink, styleBright}, fgRed, "[E]", resetStyle, " ", fgRed, s)