var mainfile = "jitter.nim"
var maininstallfile = "mug/installer.nim"
var version = "0.1.0"
task installer, "Builds the mug installer":
    switch("out", "bin/mug")
    setCommand("c", maininstallfile)

task debug, "Builds the debug version of jitter":
    echo "Setting arguments"
    switch("verbosity", "3")
    switch("define", "debug")
    switch("define", "ssl")
    switch("define", "version:" & version)
    switch("out", "bin/jtr")
    switch("opt", "speed")
    echo "Done\nCompiling.."
    setCommand("c", mainfile)

task release, "Builds the release version of jitter":
    echo "Setting arguments"
    switch("verbosity", "0")
    switch("define", "release")
    switch("define", "ssl")
    switch("define", "version:" & version)
    switch("out", "bin/jtr")
    switch("opt", "size")
    switch("hints", "off")
    switch("warnings", "off")
    echo "Done\nCompiling.."
    setCommand("c", mainfile)
