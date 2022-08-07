import os

var mainfile = "jitter.nim"
var version = "0.4.2-dev"
var nimble = getHomeDir() & ".nimble/pkgs"


switch("NimblePath", nimble)
switch("define", "version:" & version)
switch("define", "ssl")

task debug, "Builds the debug version of jitter":
    echo "Setting arguments"
    switch("verbosity", "3")
    switch("define", "debug")
    switch("out", "bin/jtr")
    switch("opt", "speed")
    echo "Done\nCompiling.."
    setCommand("c", mainfile)

task release, "Builds the release version of jitter":
    echo "Setting arguments"
    switch("verbosity", "0")
    switch("define", "release")
    switch("out", "bin/jtr")
    switch("opt", "size")
    switch("hints", "off")
    switch("warnings", "off")
    setCommand("c", mainfile)

task setup, "Installs required nimble libraries":
    exec("nimble install zippy")
    exec("nimble install argpase")