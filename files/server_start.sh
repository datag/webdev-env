#!/bin/bash

PREFIX={{WEBDEV_ENV_PATH}}

if [[ $1 == start ]]; then

	find $PREFIX/local -type d -name 'php-*' | while read d; do
		$d/sbin/php-fpm -y $d/etc/php-fpm.conf -c $d/etc/php.ini
	done

	$PREFIX/sbin/apachectl -k start

elif [[ $1 == stop ]]; then

	$PREFIX/sbin/apachectl -k stop
	killall php-fpm

else

	echo 'error: provide start|stop as argument' >&2
	exit 1;

fi


ps -A | egrep 'php-fpm|httpd'

