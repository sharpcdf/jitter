proc printHelp() =
    echo """Usage:
        jtr <command> [args]

    install [gh:|gl:|cb:|sh:]<[user/]repo>             Installs the binaries of the given repository, if avaliable.
    update <[user/]repo>                               Updates the specified binaries, or all binaries if none are specified.
    remove <[user/]repo>                               Removes the specified binaries from your system.
    search [gh:|gl:|cb:|sh:]<[user/]repo>              Searches for binaries that match the given repositories, returning them if found.
    list [gh|gl|cb|sh]                                 Lists binaries downloaded from the specified source, or all if nothing is specified.
    help                                               Prints this help.
    version                                            Prints the version of jitter

    --replace                                          Removes all other binaries with the same name after updating/installing
    --version=<tag>                                    Specifies a version to download                                          
    -ver=<tag>
    """