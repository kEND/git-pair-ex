# GitPairEx

`git-pair`... a commandline tool for quickly and cleanly managing commits as a pair.

## Installation

Clone a copy of this repository and run the following command to build and install `git-pair` into `/usr/local/bin/`:

```shell
MIX_ENV=prod mix escript.build
```

## Documentation

Documentation is pretty light at the moment.  Feel free to create a PR.  In the meantime, `git-pair -h` will bring up USAGE.

```shell
USAGE:
git-pair [OPTIONS] <SUBCOMMAND>
git-pair [OPTIONS] <ABBR1> <ABBR2>         ;   sets the pair by their abbreviations

FLAGS:
    -h, --help       Prints help information
    -v, --version    Prints version information [NImp]

OPTIONS:
        --global     Target git config for storing/retrieving authors [default: --local]
                        --global   ~/.gitconfig     Your system
                        --local   ./.git/config     Your project

SUBCOMMANDS:
    add abbr 'Person <emailaddress>'    Add an author, e.g. `git-pair add js 'John Smith <jsmith@example.com>'
    clear                               Clears the pair
    commit <commit-flags/options>       Just like regular `git commit` (approx.)
    help                                Prints this message
    remove abbr                         Remove an author by abbreviation
    show-authors                        Show list of authors
    status, st                          Returns `git status` with pairing status
```

## Contributing

### Testing

Test suite is fragile.  Specifically, `git` >= 2.30.0 is required because we use `git switch` to help test `git commit`.
