import std/os

var base = getHomeDir() & ".jitter/"

if dirExists(base):
    echo "Jitter is already installed!"
    quit()

createDir(base)
createDir(base & "bin")
createDir(base & "nerve")
createDir(base & "config")
var f = open(base & "bin/testing.txt", fmWrite)
close(f)