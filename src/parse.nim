import std/strutils
import gitlab, github, codeberg, sourcehut
##Calls the corrosponding github, gitlab, sourcehut, or codeberg procs after looking for the prefix
proc parseInput(url: string): bool =
    if url.startsWith("gh:"):
        echo "filler"
    elif url.startsWith("gl:"):
        echo "filler"
    elif url.startsWith("cb:"):
        echo "filler"
    elif url.startsWith("sh:"):
        echo "filler"
    else:
        return false