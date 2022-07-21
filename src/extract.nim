import std/[terminal, os, strutils]
from osproc import execCmdEx
import zippy/tarballs as tb
import zippy/ziparchives as za
import log
import parse
var baseDir = getHomeDir() & ".jitter/"
var nerve = baseDir & "nerve/"

#extracts the archive, runs makefiles, and adds executables to the bin
proc extract*(z, name: string, make: bool) =
    info "Extracting files"
    #extracts the archive according to the extension, or if its an appimage than just makes a directory for it and adds it to the bin
    try:
        case z.splitFile().ext:
        of ".zip":
            za.extractAll(z, nerve & name)
        of ".tgz", ".gz":
            tb.extractAll(z, nerve & name)
        of ".AppImage":
            createDir(nerve & name)
            setFilePermissions(z, {fpUserExec, fpGroupExec, fpOthersExec, fpUserRead, fpUserWrite, fpOthersRead})
            moveFile(z, nerve & name & "/" & z.extractFilename())
    except ZippyError:
        #raise
        fatal "Failed to extract archive"
    removeFile(z)
    success "Files extracted"

    #if the --no-make flag isnt passed than this happens
    if make:
        for f in walkDirRec(nerve & name):
            if f.extractFilename().toLowerAscii() == "makefile":
                info "Running Makefile in directory " & f.splitFile().dir
                if execCmdEx("make -C " & f.splitFile().dir).exitCode != 0:
                    error "Error: failed to make " & f
                else:
                    success "Done"
    
    info "Adding executables to bin"

    #Creates symlinks for executables and adds them to the bin
    #TODO check if theres no executables, if so inform and ask to remove package
    for f in walkDirRec(nerve & name):
        if hasExecPerms(f):
            if f.splitFile().ext == "" or f.splitFile().ext == ".AppImage":
                if not symlinkExists(baseDir & "bin/" & f.splitFile().name):
                    createSymlink(f, baseDir & "bin/" & f.splitFile().name)
                    success "Created symlink " & f.splitFile().name
                else:
                    error "Symlink " & f.splitFile().name & " already exists, skipping"