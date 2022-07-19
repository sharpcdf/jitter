import std/[terminal, os, httpclient, strutils]

var base = getHomeDir() & ".jitter/"
var args: seq[string]
const jtr = slurp("../bin/jtr")
var changeEnv = false
proc toEnv()

when declared(commandLineParams):
    args = commandLineParams()
else:
    styledEcho(fgRed, "Error: Unable to get arguments")
    quit()
when defined(debug):
    changeEnv = true

if args.len == 1:
    if args[0] == "upgrade":
        echo "filler"
    elif args[0] == "install":
        if dirExists(base):
            styledEcho(fgRed, "Jitter is already installed!")
            quit()
        styledEcho(fgBlue, "Creating base directory in " & base)
        createDir(base)
        styledEcho(fgYellow, "Creating bin and nerve directories")
        createDir(base & "bin") #*Where the jitter exe and symlinks to the binaries will be held
        createDir(base & "nerve") #*where the actualy binaries will be held
        styledEcho(fgGreen, "Creating config directory")
        createDir(base & "config") #*config files
        styledEcho(fgBlue, "Extracting jitter")
        var f = open(base & "bin/jtr", fmWrite)
        f.write(jtr)
        close(f)
        styledEcho(fgYellow, "Setting executable permissions")
        setFilePermissions(base & "bin/jtr", {fpOthersExec, fpUserExec, fpGroupExec, fpUserRead, fpUserWrite, fpOthersRead, fpOthersWrite})
        if changeEnv: toEnv()
        styledEcho(fgMagenta, "Done! Now you can add 'export PATH=$PATH:" & base & "bin' to your .bashrc file to add Jitter to your bash path.")
    elif args[0] == "uninstall":
        styledEcho(fgBlue, "Uninstalling Jitter")
        removeDir(getHomeDir() & ".jitter")
        styledEcho(fgGreen, "Done!")
if args.len == 0 or (args.len == 1 and args[0] == "help"):
    echo """Usage
        mug <command>

    install          Installs jitter for the current user
    uninstall        Uninstalls jitter and deletes all installed packages
    upgrade          Upgrades jitter to the newest version
    help             Displays this help
    """
proc toEnv() {.deprecated: "Should not be used because of the possible risks".} =
    styledEcho(fgGreen, "Adding to path..")
    var fcheck = readFile(getHomeDir() & ".bashrc")
    if not fcheck.contains("export PATH=$PATH:" & base & "bin"):
        var f = open(getHomeDir() & ".bashrc", fmAppend)
        f.writeLine("export PATH=$PATH:" & base & "bin")
        f.close()
    else:
        echo ".bashrc file already contains appendage"
    if fileExists("/usr/bin/fish"):
        styledEcho(fgGreen, "Fish shell found, appending jitter to path")
        fcheck = readFile(getHomeDir() & ".config/fish/config.fish")
        if fcheck.contains("set -U fish_user_paths $fish_user_paths " & base & "bin"):
            var f = open(getHomeDir() & ".config/fish/config.fish", fmAppend)
            f.writeLine("set -U fish_user_paths $fish_user_paths " & base & "bin")
        else:
            echo "config.fish file already contains appendage"