################################################################################
# webdev-env Makefile
#
# Author: Dominik D. Geyer <dominik.geyer@gmail.com>
# License: GPLv3
################################################################################

PKGBOX_CONFIG = $(CURDIR)/pkgbox_config

# macro for reading pkgbox option from config
cfgval = $(shell bash -c 'declare -A O && source $(PKGBOX_CONFIG) && echo $${O[$(1)]}')

PKGBOX_BASE := $(call cfgval,base)
PKGBOX_PKG := $(call cfgval,packages)
PKGBOX_BUILD := $(call cfgval,build)
PREFIX := $(call cfgval,prefix)

PKGBOX = $(CURDIR)/pkgbox/pkgbox -v -c "$(PKGBOX_CONFIG)"

FILES = $(CURDIR)/files

# include custom build/target options
include config.mk


################################################################################

post_config: config_replace config_demo

config_replace:
	find $(PREFIX) -type f | xargs sed -i \
		-e 's/{{WEBDEV_ENV_PATH}}/$(subst /,\/,$(PREFIX))/g' \
		-e 's/{{WEBDEV_ENV_WWW_USER}}/$(WWW_USER)/g' \
		-e 's/{{WEBDEV_ENV_WWW_GROUP}}/$(WWW_GROUP)/g' \
		-e 's/{{WEBDEV_ENV_WWW_SERVER_NAME}}/$(WWW_SERVER_NAME)/g' \
		-e 's/{{WEBDEV_ENV_WWW_SERVER_ADMIN}}/$(WWW_SERVER_ADMIN)/g' \
		-e 's/{{WEBDEV_ENV_WWW_ROOTPATH}}/$(subst /,\/,$(WWW_ROOTPATH))/g' \
		-e 's/{{WEBDEV_ENV_HTTP_PORT}}/$(HTTP_PORT)/g' \
		-e 's/{{WEBDEV_ENV_HTTPS_PORT}}/$(HTTPS_PORT)/g'

config_demo: $(WWW_ROOTPATH)/index.php

$(WWW_ROOTPATH)/index.php:
	mkdir -p $(WWW_ROOTPATH)
	echo '<?php phpinfo();' >$(WWW_ROOTPATH)/index.php


clean:
ifneq (,$(PKGBOX_BUILD))
	-rm -rf "$(PKGBOX_BUILD)"
else
	$(error "Oops... PKGBOX_BUILD not defined or empty!")
endif


################################################################################
# common

common:
	mkdir -pv $(PREFIX)/local/sbin
	cp -vt $(PREFIX)/local/sbin $(FILES)/server_test.sh


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
	# Scons workaround
	-$(SUDO) rm -fv $(PREFIX)/lib/libserf*.so*
	
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

apache_modules: mod_macro


################################################################################
# Apache mod_macro

mod_macro: mod_macro_install

mod_macro_build: apache
	$(PKGBOX) -V $(MOD_MACRO_VERSION) $(MOD_MACRO_PKG) compile

mod_macro_install: mod_macro_build
	$(PKGBOX) -V $(MOD_MACRO_VERSION) $(MOD_MACRO_PKG) install


################################################################################
# Apache Subversion (with mod_dav_svn)

subversion: subversion_install

subversion_build: apache serf
	$(PKGBOX) -V $(SUBVERSION_VERSION) $(SUBVERSION_PKG) compile

subversion_install: subversion_build
	$(PKGBOX) -V $(SUBVERSION_VERSION) $(SUBVERSION_PKG) install


################################################################################
# PHP

php: $(PHP) 

# macro for determining version
php_tgt2ver = $($(subst php-,PHP_,$(1))_VERSION)

php_commonsetup:
	# No common PHP setup

php-%: php_commonsetup php-%_config
	@echo Done with PHP $@ version $($(subst php-,PHP_,$@)_VERSION)

php-%_build:
	$(PKGBOX) -V $(call php_tgt2ver,$(@:%_build=%)) \
		-D prefix=$(PREFIX)/local/php-$(call php_tgt2ver,$(@:%_build=%)) \
		-F -apxs \
		-F php:fpm \
		-F php:config-file-path=$(PREFIX)/local/php-$(call php_tgt2ver,$(@:%_build=%))/etc \
		-F php:config-file-scan-dir=$(PREFIX)/local/php-$(call php_tgt2ver,$(@:%_build=%))/etc/conf.d \
		$(PHP_PKG) compile

php-%_install: php-%_build
	$(PKGBOX) -V $(call php_tgt2ver,$(@:%_install=%)) \
		-D prefix=$(PREFIX)/local/php-$(call php_tgt2ver,$(@:%_install=%)) \
		$(PHP_PKG) install

php-%_config: php-%_install
	@#echo CONFIG for $(@:%_config=%) version $(call php_tgt2ver,$(@:%_config=%))
	
	# symlink installation, e.g. php-5.3.21 -> php-53
	if [ "$(@:%_config=%)" != "php-$(call php_tgt2ver,$(@:%_config=%))" ]; then \
		rm -f $(PREFIX)/local/$(@:%_config=%); \
		ln -vs php-$(call php_tgt2ver,$(@:%_config=%)) $(PREFIX)/local/$(@:%_config=%); \
	fi
	
	# configuration
	mkdir -p $(PREFIX)/local/$(@:%_config=%)/etc
	cp -rvt $(PREFIX)/local/$(@:%_config=%)/etc $(FILES)/php/php-fpm.conf $(FILES)/php/php.ini $(FILES)/php/conf.d


################################################################################
# PHP Extensions

# build extensions for all PHP instances by default
php_extensions: $(PHP:%=zend_opcache_%) $(PHP:%=xdebug_%)

# enable PHP Zend extension; (CONFIG_load_zend_extension,title,extension,PHP-target)
define CONFIG_load_zend_extension
@if ! grep -qs "$(2)" $(PREFIX)/local/$(3)/etc/conf.d/extensions.ini; then \
	echo "=== Enabling Zend extension '$(1)' ($(2)) for $(3) ==="; \
	{ \
		echo; echo "; $(1)"; \
		echo "zend_extension = $(shell $(PREFIX)/local/$(3)/bin/php-config --extension-dir)/$(2)"; \
		echo; \
	} >>$(PREFIX)/local/$(3)/etc/conf.d/extensions.ini; \
else \
	echo "Zend extension '$(1)' is already enabled for $(3), skipping..."; \
fi
endef

# Zend OPcache (bundled with >=PHP-5.5)
# ====================================================================
zend_opcache_php-%:
	@echo "Not building Zend OPcache for $(@:zend_opcache_%=%) as it's already bundled."
	
	$(call CONFIG_load_zend_extension,"Zend OPcache",opcache.so,$(@:zend_opcache_%=%))

zend_opcache_php-53 zend_opcache_php-54:
	@echo "=== Zend OPcache for $(@:zend_opcache_%=%) version $(ZEND_OPCACHE_VERSION) ==="
	$(PKGBOX) -V $(ZEND_OPCACHE_VERSION) \
		-D build=$(PKGBOX_BUILD)/work/$(@:zend_opcache_%=%)_extensions -D prefix=$(PREFIX)/local/$(@:zend_opcache_%=%) \
		-F phpize=$(PREFIX)/local/$(@:zend_opcache_%=%)/bin/phpize -F php-config=$(PREFIX)/local/$(@:zend_opcache_%=%)/bin/php-config \
		$(ZEND_OPCACHE_PKG) install
	
	$(call CONFIG_load_zend_extension,"Zend OPcache",opcache.so,$(@:zend_opcache_%=%))

# Xdebug
# ======
xdebug_php-%:
	@echo "=== Xdebug for $(@:xdebug_%=%) version $(XDEBUG_VERSION) ==="
	$(PKGBOX) -V $(XDEBUG_VERSION) \
		-D build=$(PKGBOX_BUILD)/work/$(@:xdebug_%=%)_extensions -D prefix=$(PREFIX)/local/$(@:xdebug_%=%) \
		-F phpize=$(PREFIX)/local/$(@:xdebug_%=%)/bin/phpize -F php-config=$(PREFIX)/local/$(@:xdebug_%=%)/bin/php-config \
		$(XDEBUG_PKG) install
	
	$(call CONFIG_load_zend_extension,"Xdebug",xdebug.so,$(@:xdebug_%=%))

# 2014-12-25: Xdebug 2.2.x (and master, too) won't compile for PHP-master
xdebug_php-master:
	@echo "Xdebug $(XDEBUG_VERSION) for $(@:xdebug_%=%) won't compile; skipping..."


################################################################################
## MariaDB

mariadb: mariadb_config

mariadb_build:
	$(PKGBOX) -V $(MARIADB_VERSION) $(MARIADB_PKG) compile

mariadb_install: mariadb_build
	$(PKGBOX) -V $(MARIADB_VERSION) $(MARIADB_PKG) install
	rm -rf $(PREFIX)/local/mariadb/mysql-test

mariadb_config: mariadb_install
	mkdir -p $(PREFIX)/local/mariadb/etc
	cp -vt $(PREFIX)/local/mariadb/etc $(FILES)/mysql/config/my.cnf
	
	# FIXME: use pkgbox-configured
	sed -i -e "s~^# datadir = .....~datadir = $(PREFIX)/var/mysql/data~" $(PREFIX)/local/mariadb/etc/my.cnf
	
	( cd $(PREFIX)/local/mariadb && ./scripts/mysql_install_db --defaults-file=$(PREFIX)/local/mariadb/etc/my.cnf )

################################################################################

.PHONY: clean

