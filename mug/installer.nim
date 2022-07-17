import std/[terminal, os, httpclient]

var base = getHomeDir() & ".jitter/"
var args: seq[string]
when declared(commandLineParams):
    args = commandLineParams()
else:
    styledEcho(fgRed, "Error: Unable to get arguments")
    quit()

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
        var f = open(base & "bin/testing.txt", fmWrite)
        close(f)

if args.len == 0 or (args.len == 1 and args[0] == "help"):
    echo """Usage
        mug <command>

    install          Installs jitter for the current user
    upgrade          Upgrades jitter with the newest version
    help             Displays this help
    """