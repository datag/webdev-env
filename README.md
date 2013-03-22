# webdev-env #

webdev-env provides a development environment targeted at web development.

Required software such as a webserver and scripting languages are built from
source code and will be provided with a default configuration.


## How to setup? ##

The build system used is [pkgbox](https://github.com/datag/pkgbox).
Required dependencies (libraries) are in most cases *not* built/installed
automatically but need to be installed with your distribution's package manager.
Most packages of webdev-env will be built against installed system libraries and
is therefore not completely independent.

### pkgbox prerequisites ###

The directory `pkgbox` is a Git submodule pointing to
[datag/pkgbox](https://github.com/datag/pkgbox)
and the directory `pkg` is a Git
submodule pointing to
[datag/pkgbox-packages](https://github.com/datag/pkgbox-packages). Both need to
be cloned before invoking the build process.

    $ git submodule init
    $ git submodule update

### Configuration ###

The file `config.mk` specifies the to be built package versions and some target
specific options.

The file `pkgbox_config` holds the configuration for the
build system pkgbox.

The directory `files` holds package specific configuration files.

### Build, install and configure ###

    $ make

