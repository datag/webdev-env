# webdev-env #

webdev-env provides a development environment targeted at web development.

Required software such as a webserver and scripting languages are built from
source code and will be provided with a default configuration.


## What does it do? ##

Currently this project is heavily aimed at a "LAMP"-like system. However, one
future goal is to provide a generic and modular development environment for web
development related tasks.

This is the current setup (as of 2015-06-06):

* **Apache**-2.4 (latest stable)
  * **PHP-FPM** (FastCGI Process Manager)
  * **mod\_macro** (Support for basic configuration templates)
* Multiple concurrent **PHP** instances
  * PHP-5.3 (latest)
  * PHP-5.4 (latest)
  * PHP-5.5 (latest)
  * PHP-5.6 (latest)
  * PHP-master (branch master)
* External PHP extensions (for each PHP instance)
  * **Zend OPcache** (formerly Zend Optimizer+, which was merged into PHP as of PHP-5.5)
  * **Xdebug** (Debugger/Profiler)
* **MariaDB**-10.0.15
* **Subversion**-1.8.13 


## How to setup? ##

The build system used is [pkgbox](https://github.com/datag/pkgbox).
Required dependencies (libraries) are in most cases *not* built/installed
automatically but need to be installed with your distribution's package manager.
Most packages of webdev-env will be built against installed system libraries and
is therefore not completely independent.

### Example dependencies for a Debian system ###

    # apt-get install build-essential git scons autoconf automake libtool bison re2c
    # OLDER bison version might be needed! E.g. Debian jessie; download and install with `dpkg -i`; https://packages.debian.org/wheezy/amd64/libbison-dev/download https://packages.debian.org/wheezy/amd64/bison/download

    # apt-get install libpcre3-dev zlib1g-dev libssl-dev libsqlite3-dev libxml2-dev libcurl4-openssl-dev libbz2-dev libreadline-dev libjpeg-dev libpng12-dev libxpm-dev libfreetype6-dev libmysqlclient-dev libgd2-xpm-dev libgmp-dev libsasl2-dev libmhash-dev unixodbc-dev freetds-dev libpspell-dev libsnmp-dev libtidy-dev libxslt1-dev libmcrypt-dev
    FIXME
    
    ## see also: http://zgadzaj.com/how-to-install-php-53-and-52-together-on-ubuntu-1204

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

