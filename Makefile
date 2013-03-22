################################################################################
# webdev-env Makefile
#
# Copyright 2013  Dominik D. Geyer <dominik.geyer@gmail.com>
# License: GPLv3
################################################################################

PKGBOX_CONFIG = $(CURDIR)/pkgbox_config

# macro for reading pkgbox option from config
cfgval = $(shell bash -c 'declare -A O && source $(PKGBOX_CONFIG) && echo $${O[$(1)]}')

PKGBOX_BASE := $(call cfgval,base)
PKGBOX_PKG := $(call cfgval,packages)
PKGBOX_BUILD := $(call cfgval,build)
PREFIX := $(call cfgval,prefix)

PKGBOX = $(CURDIR)/pkgbox/pkgbox -vv -c "$(PKGBOX_CONFIG)"

FILES = $(CURDIR)/files

WWW_USER = $(USER)
WWW_GROUP = $(USER)

SUDO = sudo

################################################################################

APR_PKG = dev-libs/apr
APR_VERSION = 1.4.6

APR_UTIL_PKG = dev-libs/apr-util
APR_UTIL_VERSION = 1.5.1

SERF_PKG = net-libs/serf
SERF_VERSION = 1.2.0

APACHE_PKG = www-servers/apache
APACHE_VERSION = 2.4.3

MOD_FCGID_PKG = www-apache/mod_fcgid
MOD_FCGID_VERSION = 2.3.7

MOD_MACRO_PKG = www-apache/mod_macro
MOD_MACRO_VERSION = 1.2.1

SUBVERSION_PKG = dev-vcs/subversion
SUBVERSION_VERSION = 1.7.8

PHP_PKG = dev-lang/php
PHP_53_VERSION = 5.3.23
PHP_54_VERSION = 5.4.11
PHP_55_VERSION = PHP-5.5
PHP_master_VERSION = master

# PHP instances to build
PHP = php-53 php-54 php-55 php-master

ZEND_OPTIMIZERPLUS_PKG = dev-php/pecl-zendoptimizerplus
ZEND_OPTIMIZERPLUS_VERSION = master

XDEBUG_PKG = dev-php/xdebug
XDEBUG_VERSION = 2.2.1

################################################################################

all: apache apache_modules subversion php php_extensions post_config

post_config:
	find $(PREFIX) -type f | xargs sed -i 's/{{WEBDEV_ENV_PATH}}/$(subst /,\/,$(PREFIX))/g'

clean:
	-[ -n "$(PKGBOX_BUILD)" ] && rm -rf $(PKGBOX_BUILD)/* || echo "Oops... PKGBOX_BUILD not defined!"

################################################################################
# Apache Portable Runtime

apr: apr_install

apr_build:
	$(PKGBOX) -V $(APR_VERSION) $(APR_PKG) compile

apr_install: apr_build
	$(PKGBOX) -V $(APR_VERSION) $(APR_PKG) install

################################################################################
# Apache Portable Runtime Utility

apr-util: apr-util_install

apr-util_build: apr
	$(PKGBOX) -V $(APR_UTIL_VERSION) $(APR_UTIL_PKG) compile

apr-util_install: apr-util_build
	$(PKGBOX) -V $(APR_UTIL_VERSION) $(APR_UTIL_PKG) install

################################################################################
# HTTP client library built upon APR

serf: serf_install

serf_build: apr-util
	$(PKGBOX) -V $(SERF_VERSION) $(SERF_PKG) compile

serf_install: serf_build
	$(PKGBOX) -V $(SERF_VERSION) $(SERF_PKG) install

################################################################################
# Apache httpd

apache: apache_config

apache_build: apr-util
	$(PKGBOX) -V $(APACHE_VERSION) $(APACHE_PKG) compile

apache_install: apache_build
	$(PKGBOX) -V $(APACHE_VERSION) $(APACHE_PKG) install
	rm -rf $(PREFIX)/share/apache2/manual

apache_config: apache_install
	cp -rvt $(PREFIX)/etc/apache2 $(FILES)/apache/config/*
	
	$(SUDO) mkdir -p $(PREFIX)/var/apache2
	$(SUDO) chown -R $(WWW_USER):$(WWW_GROUP) $(PREFIX)/var/apache2

################################################################################
# Apache modules

apache_modules: mod_fcgid mod_macro

################################################################################
# Apache mod_fcgid

mod_fcgid: mod_fcgid_install

mod_fcgid_build: apache
	$(PKGBOX) -V $(MOD_FCGID_VERSION) $(MOD_FCGID_PKG) compile

mod_fcgid_install: mod_fcgid_build
	$(PKGBOX) -V $(MOD_FCGID_VERSION) $(MOD_FCGID_PKG) install

################################################################################
# Apache mod_macro

mod_macro: mod_macro_install

mod_macro_build: apache
	$(PKGBOX) -V $(MOD_MACRO_VERSION) $(MOD_MACRO_PKG) compile

mod_macro_install: mod_macro_build
	$(PKGBOX) -V $(MOD_MACRO_VERSION) $(MOD_MACRO_PKG) install

################################################################################
# Apache Subversion and mod_dav_svn

subversion: subversion_install

subversion_build: apache
	$(PKGBOX) -V $(SUBVERSION_VERSION) $(SUBVERSION_PKG) compile

subversion_install: subversion_build
	$(PKGBOX) -V $(SUBVERSION_VERSION) $(SUBVERSION_PKG) install

################################################################################
# PHP

php: $(PHP) 

# macro for determining version
php_tgt2ver = $($(subst php-,PHP_,$(1))_VERSION)

php_commonsetup:
	mkdir -p $(PREFIX)/local/bin
	$(SUDO) cp -vt $(PREFIX)/local/bin $(FILES)/php/php-wrapper
	$(SUDO) chown $(WWW_USER):$(WWW_GROUP) $(PREFIX)/local/bin/php-wrapper

php-%: php_commonsetup php-%_config
	@echo Done with PHP $@ version $($(subst php-,PHP_,$@)_VERSION)

php-%_build:
	$(PKGBOX) -V $(call php_tgt2ver,$(@:%_build=%)) \
		-D prefix=$(PREFIX)/local/php-$(call php_tgt2ver,$(@:%_build=%)) \
		-F -apxs \
		-F php:config-file-path=$(PREFIX)/local/php-$(call php_tgt2ver,$(@:%_build=%))/etc \
		-F php:config-file-scan-dir=$(PREFIX)/local/php-$(call php_tgt2ver,$(@:%_build=%))/etc/conf.d \
		$(PHP_PKG) compile

php-%_install: php-%_build
	$(PKGBOX) -V $(call php_tgt2ver,$(@:%_install=%)) -D prefix=$(PREFIX)/local/php-$(call php_tgt2ver,$(@:%_install=%)) $(PHP_PKG) install

php-%_config: php-%_install
	@#echo CONFIG for $(@:%_config=%) version $(call php_tgt2ver,$(@:%_config=%))
	
	# symlink installation, e.g. php-5.3.21 -> php-53
	if [ "$(@:%_config=%)" != "php-$(call php_tgt2ver,$(@:%_config=%))" ]; then \
		rm -f $(PREFIX)/local/$(@:%_config=%); \
		ln -vs php-$(call php_tgt2ver,$(@:%_config=%)) $(PREFIX)/local/$(@:%_config=%); \
	fi
	
	# configuration
	mkdir -p $(PREFIX)/local/$(@:%_config=%)/etc
	cp -rvt $(PREFIX)/local/$(@:%_config=%)/etc $(FILES)/php/php.ini $(FILES)/php/conf.d
	
	# fcgid-wrapper 
	rm -f $(PREFIX)/local/bin/$(@:%_config=%)-wrapper
	ln -s php-wrapper $(PREFIX)/local/bin/$(@:%_config=%)-wrapper

################################################################################
# PHP Extensions

php_extensions: $(PHP:%=zend_optimizerplus_%) $(PHP:%=xdebug_%)

# Zend OPcache (formerly Zend Optimizer+)
# =======================================
# FIXME: recent change: for php >= 55 (commit 34d3202edac0a56b91eb8a305fc1801bbd9b7653) Zend OPcache is already integrated
$(PHP:%=zend_optimizerplus_%):
	@echo "=== Zend Optimizer+ for $(@:zend_optimizerplus_%=%) version $(ZEND_OPTIMIZERPLUS_VERSION) ==="
	$(PKGBOX) -V $(ZEND_OPTIMIZERPLUS_VERSION) \
		-D build=$(PKGBOX_BUILD)/$(@:zend_optimizerplus_%=%) -D prefix=$(PREFIX)/local/$(@:zend_optimizerplus_%=%) \
		-F phpize=$(PREFIX)/local/$(@:zend_optimizerplus_%=%)/bin/phpize -F php-config=$(PREFIX)/local/$(@:zend_optimizerplus_%=%)/bin/php-config \
		$(ZEND_OPTIMIZERPLUS_PKG) install
	
	# append to extension-load-config (IMPORTANT: must be loaded _before_ Xdebug!)
	echo -e "; Zend OPcache\nzend_extension = $(shell $(PREFIX)/local/$(@:zend_optimizerplus_%=%)/bin/php-config --extension-dir)/opcache.so\n" \
		>>$(PREFIX)/local/$(@:zend_optimizerplus_%=%)/etc/conf.d/extensions.ini

# Xdebug
# ======
$(PHP:%=xdebug_%):
	@echo "=== Xdebug for $(@:xdebug_%=%) version $(XDEBUG_VERSION) ==="
	$(PKGBOX) -V $(XDEBUG_VERSION) \
		-D build=$(PKGBOX_BUILD)/$(@:xdebug_%=%) -D prefix=$(PREFIX)/local/$(@:xdebug_%=%) \
		-F phpize=$(PREFIX)/local/$(@:xdebug_%=%)/bin/phpize -F php-config=$(PREFIX)/local/$(@:xdebug_%=%)/bin/php-config \
		$(XDEBUG_PKG) install
	
	# append to extension-load-config
	echo -e "; Xdebug\nzend_extension = $(shell $(PREFIX)/local/$(@:xdebug_%=%)/bin/php-config --extension-dir)/xdebug.so\n" \
		>>$(PREFIX)/local/$(@:xdebug_%=%)/etc/conf.d/extensions.ini

# 2.2.1 and master (2013-02-23) won't compile for PHP-5.5-dev and PHP-master
xdebug_php-55 xdebug_php-master:
	@echo "Xdebug $(XDEBUG_VERSION) for $(@:xdebug_%=%) won't compile; skipping..."

################################################################################

.PHONY: clean

