#[
    Package folder names have the following format:
        REPOOWNER__REPONAME__VERSION
]#

import std/[terminal, os, strutils]
from osproc import execCmdEx
import zippy/tarballs as tb
import zippy/ziparchives as za
var baseDir = getHomeDir() & ".jitter/"
var nerve = baseDir & "nerve/"
proc extract*(z, name: string, make: bool) =
    styledEcho(fgBlue, "Extracting files")
    if z.splitFile().ext == ".zip":
        za.extractAll(z, nerve & name)
    else:
        tb.extractAll(z, nerve & name)
    removeFile(z)
    styledEcho(fgGreen, "Files extracted")
    #if the --no-make flag isnt passed than this happens
    if make:
        for f in walkDirRec(nerve & name):
            if f.extractFilename().toLowerAscii() == "makefile":
                if execCmdEx("make -C " & f.splitFile().dir).exitCode != 0:
                    styledEcho(fgRed, "Error: failed to make " & f)
    styledEcho(fgBlue, "Adding executables to bin")
    #Creates symlinks for executables and adds them to the bin
    for f in walkDir(nerve & name):
        if f.kind == pcDir: continue
        var perms = getFilePermissions(f.path)
        if (fpGroupExec in perms or fpOthersExec in perms or fpUserExec in perms) and f.path.splitFile().ext == "":
            createSymlink(f.path, baseDir & "bin/" & extractFilename(f.path))
            styledEcho(fgGreen, "Created symlink ", fgYellow, extractFilename(f.path))