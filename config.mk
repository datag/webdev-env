################################################################################
# webdev-env config
################################################################################

# Target config
WWW_USER := $(USER)
WWW_GROUP := $(USER)
WWW_SERVER_NAME := webdev-env
WWW_SERVER_ADMIN := admin@webdev-env
WWW_ROOTPATH := $(PREFIX)/var/www
HTTP_PORT := 8080
HTTPS_PORT := 8443


# Command to gain super user privileges
SUDO := sudo

################################################################################

# === Misc libraries ===
APR_PKG = dev-libs/apr
APR_VERSION = 1.5.1

APR_UTIL_PKG = dev-libs/apr-util
APR_UTIL_VERSION = 1.5.4

SERF_PKG = net-libs/serf
SERF_VERSION = 1.3.8


# === Apache and modules ===
APACHE_PKG = www-servers/apache
APACHE_VERSION = 2.4.10

MOD_MACRO_PKG = www-apache/mod_macro
MOD_MACRO_VERSION = 1.2.1


# === Subversion ===
SUBVERSION_PKG = dev-vcs/subversion
SUBVERSION_VERSION = 1.7.8


# === PHP and extensions ===
PHP_PKG = dev-lang/php
PHP_53_VERSION = PHP-5.3
PHP_54_VERSION = PHP-5.4
PHP_55_VERSION = PHP-5.5
PHP_56_VERSION = PHP-5.6
PHP_master_VERSION = master
# last known good version: 0c45d1d

# PHP instances to build
PHP = php-53 php-54 php-55 php-56 php-master


ZEND_OPCACHE_PKG = dev-php/pecl-zendopcache
ZEND_OPCACHE_VERSION = master
# last known good version: 41f4a58

XDEBUG_PKG = dev-php/xdebug
XDEBUG_VERSION = xdebug_2_2
# last known good version: b1ce1e3


# === MariaDB ===
MARIADB_PKG = dev-db/mariadb
MARIADB_VERSION = 10.0.15

