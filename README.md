# webdev-env #

webdev-env provides a development environment targeted at web development.

Required software such as a webserver and scripting languages are built from
source code and will be provided with a default configuration.


## What does it do? ##

Currently this project is heavily aimed at a "LAMP"-like system. However, one
future goal is to provide a generic and modular development environment for web
development related tasks.

This is the current setup (as of 2013-03-23):

* **Apache**-2.4 (latest stable)
  * **mod\_fcgid** (FastCGI implementation)
  * **mod\_macro** (Support for basic configuration templates)
* Multiple concurrent **PHP** instances
  * PHP-5.3 (latest stable)
  * PHP-5.4 (latest stable)
  * PHP-5.5 (branch PHP-5.5; to be released soon)
  * PHP-master (branch master; bleeding edge preview of PHP-5.6)
* External PHP extensions (for each PHP instance)
  * **Zend OPcache** (formerly Zend Optimizer+, which was merged into PHP as of PHP-5.5)
  * **Xdebug** (Debugger/Profiler)
* **MySQL**-5.6 (latest stable)
* **Subversion**-1.7 (latest stable) serving repositories via Apache2-DAV module


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

