#[
    Package folder names have the following format:
        REPOOWNER__REPONAME__VERSION
]#

import std/[terminal, os, strutils]
from osproc import execCmdEx
import zippy/tarballs

var baseDir = getHomeDir() & ".jitter/"
var nerve = baseDir & "nerve/"
proc extract*(tarball, name: string, make: bool) =
    styledEcho(fgBlue, "Extracting files")
    extractAll(tarball, nerve & name)
    removeFile(tarball)
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