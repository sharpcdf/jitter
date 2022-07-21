#[
    Package folder names have the following format:
        REPOOWNER__REPONAME__VERSION
]#

import std/[terminal, os, strutils]
from osproc import execCmdEx
import zippy/tarballs as tb
import zippy/ziparchives as za
import log

var baseDir = getHomeDir() & ".jitter/"
var nerve = baseDir & "nerve/"
#TODO add support for appimages
proc extract*(z, name: string, make: bool) =
    info "Extracting files"
    try:
        if z.splitFile().ext == ".zip":
            za.extractAll(z, nerve & name)
        else:
            tb.extractAll(z, nerve & name)
    except ZippyError:
        #raise
        fatal "Failed to extract archive"
    removeFile(z)
    success "Files extracted"

    #if the --no-make flag isnt passed than this happens
    if make:
        for f in walkDirRec(nerve & name):
            if f.extractFilename().toLowerAscii() == "makefile":
                if execCmdEx("make -C " & f.splitFile().dir).exitCode != 0:
                    fatal "Error: failed to make " & f
    
    info "Adding executables to bin"

    #Creates symlinks for executables and adds them to the bin
    for f in walkDir(nerve & name):
        if f.kind == pcDir: continue
        var perms = getFilePermissions(f.path)
        if (fpGroupExec in perms or fpOthersExec in perms or fpUserExec in perms) and f.path.splitFile().ext == "":
            createSymlink(f.path, baseDir & "bin/" & extractFilename(f.path))
            success "Created symlink " & extractFilename(f.path)