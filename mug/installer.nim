import std/[terminal, os, httpclient, strutils]
import ../src/log
var base = getHomeDir() & ".jitter/"
var args: seq[string]
const jtr = slurp("../bin/jtr")
proc addEnv()

when declared(commandLineParams):
    args = commandLineParams()
else:
    fatal "Unable to get arguments"

if args.len == 1:
    if args[0] == "upgrade":
        writeFile(base & "bin/jtr", jtr)
    elif args[0] == "install":
        if dirExists(base):
            fatal "Jitter is already installed!"
            quit()
        info "Creating base directory in " & base
        createDir(base)

        info "Creating bin and nerve directories"
        createDir(base & "bin") #*Where the jitter exe and symlinks to the binaries will be held
        createDir(base & "nerve") #*where the actualy binaries will be held

        info "Creating config directory"
        createDir(base & "config") #*config files

        info "Extracting Jitter"
        writeFile(base & "bin/jtr", jtr)

        info "Setting executable permissions"
        setFilePermissions(base & "bin/jtr", {fpOthersExec, fpUserExec, fpGroupExec, fpUserRead, fpUserWrite, fpOthersRead, fpOthersWrite})
        ask "Do you want to add Jitter to your path? [y/N]"
        var i = readLine(stdin)
        if i == "yes" or i == "y":
            addEnv()
        elif i == "no" or i == "n" or i == "":
            styledEcho(fgMagenta, "Done! Now you can add 'export PATH=$PATH:" & base & "bin' to your .bashrc file to add Jitter to your bash path.")
    elif args[0] == "uninstall":
        if dirExists(getHomeDir() & ".jitter"):
            info "Uninstalling Jitter"
            removeDir(getHomeDir() & ".jitter")
            success "Done!"
        else:
            fatal "Error: No jitter path was found."

if args.len == 0 or (args.len == 1 and args[0] == "help"):
    echo """Usage
        mug <command>

    install          Installs jitter for the current user
    uninstall        Uninstalls jitter and deletes all installed packages
    upgrade          Upgrades jitter to the newest version
    help             Displays this help
    """

proc addEnv() =
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
        if not fcheck.contains("set -U fish_user_paths $fish_user_paths " & base & "bin"):
            var f = open(getHomeDir() & ".config/fish/config.fish", fmAppend)
            f.writeLine("set -U fish_user_paths $fish_user_paths " & base & "bin")
        else:
            echo "config.fish file already contains appendage"