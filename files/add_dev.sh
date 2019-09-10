#!
apt-get update \
&& apt-get install -y \
$PHPIZE_DEPS \
	automake \
	gettext \
	libtool \
	nasm \
	libmariadbclient-dev \
	libpq-dev \
	libgd-dev \
	libpng-dev \
	libwebp-dev \
	libxpm-dev \
	zlib1g-dev \
	libzip-dev \
	libfreetype6-dev \
	libbz2-dev \
	libexif-dev \
	libxmlrpc-core-c3-dev \
	libpcre3-dev \
	libgettextpo-dev \
	libxslt-dev \
	libldap2-dev \
	libc-client2007e-dev \
	libkrb5-dev \
	libicu-dev \
	curl \
	libmagick++-dev \
	libsodium-dev \
	&& :

