#//----------------------------------------------------------------------------
#// PHP7 FastCGI Server ( for KUSANAGI Runs on Docker )
#//----------------------------------------------------------------------------
FROM alpine:3.10
MAINTAINER kusanagi@prime-strategy.co.jp

# Environment variable
ARG APCU_VERSION=5.1.17
ARG APCU_BC_VERSION=1.0.5
ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c
ENV KUSANAGI_PHP_DEPS \
		file \
		binutils \
		gnupg \
		wget \
		build-base \
		automake \
		gettext \
		libtool \
		nasm \
		mariadb \
		mariadb-dev \
		postgresql \
		postgresql-dev \
		gd-dev \
		libpng-dev \
		libwebp-dev \
		libxpm-dev \
		zlib-dev \
		libzip-dev \
		freetype-dev \
		bzip2-dev \
		libexif-dev \
		xmlrpc-c-dev \
		pcre-dev \
		gettext-dev \
		libxslt-dev \
		pcre-dev \
		openldap-dev \
		imap-dev \
		icu-dev \
		curl \
		imagemagick \
		imagemagick-dev \
		libsodium \
		libsodium-dev \
		gettext \
		argon2-dev \
		coreutils \
		curl-dev \
		libjpeg-turbo-dev \
		libedit-dev \
		libxml2-dev \
		openssl-dev \
		sqlite-dev 

# persistent / runtime deps
RUN apk add --no-cache \
		ca-certificates \
		curl \
		tar \
		xz \
# https://github.com/docker-library/php/issues/494
		openssl

# add user
RUN : set -x \
	&& apk update \
	&& apk upgrade \
	&& apk add --virtual .user shadow \
	&& groupadd -g 1001 www \
	&& useradd -d /var/lib/www -s /bin/nologin -g www -u 1001 -M  httpd \
        && groupadd -g 1000 kusanagi \
        && useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
        && chmod 755 /home/kusanagi \
	&& apk del --purge .user \
	&& mkdir -p /var/www/html \
	&& chown -R httpd:www /var/www/html \
	&& mkdir -p /usr/local/etc/php/conf.d/ \
	&& :

COPY files/*.ini /usr/local/etc/php/conf.d/
COPY files/opcache*.blacklist /usr/local/etc/php.d/
COPY files/www.conf /usr/local/etc/php-fpm.d/www.conf.template
COPY files/docker-php-ext-configure /usr/local/bin
COPY files/docker-php-ext-enable /usr/local/bin
COPY files/docker-php-ext-install /usr/local/bin

##<autogenerated>##
ENV PHP_EXTRA_CONFIGURE_ARGS --enable-fpm --with-fpm-user=www-data --with-fpm-group=www-data --disable-cgi
##</autogenerated>##

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

ENV GPG_KEYS 1729F83938DA44E27BA0F4D3DBDB397470D12172 B1B44D8F021E4E2D6021E995DC9FF8D3EE5AF27F

ENV PHP_VERSION 7.2.21
ENV PHP_URL="https://www.php.net/get/php-${PHP_VERSION}.tar.xz/from/this/mirror" PHP_ASC_URL="https://www.php.net/get/php-${PHP_VERSION}.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="de06aff019d8f5079115795bd7d8eedd4cd03daecb62d58abb18f492dd995c95" PHP_MD5=""
ENV PHP_INI_DIR /usr/local/etc/php

COPY files/docker-php-source /usr/local/bin/

RUN : \
	&& apk update \
	&& apk add --update --no-cache --virtual .build-php \
		$PHPIZE_DEPS \
		$KUSANAGI_PHP_DEPS \
	&& apk add pngquant optipng jpegoptim ssmtp \
	&& cd /tmp \
\
# Get PHP7.2
\
	&& mkdir -p /var/lib/php7/session /var/lib/php7/wsdlcache  \
	&& mkdir -p /usr/src \
	&& cd /usr/src \
	&& wget -O php.tar.xz "$PHP_URL" \
	&& ([ -n "$PHP_SHA256" ] && echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c - || true) \
	&& ([ -n "$PHP_MD5" ] && echo "$PHP_MD5 *php.tar.xz" | md5sum -c - || true) \
	&& if [ -n "$PHP_ASC_URL" ]; then \
		wget -O php.tar.xz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			/usr/bin/gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
		done; \
		/usr/bin/gpg --batch --verify php.tar.xz.asc php.tar.xz; \
		command -v gpgconf > /dev/null && gpgconf --kill all; \
		rm -rf "$GNUPGHOME"; \
	fi \
\
# Build PHP7.2
\
	&& export CFLAGS="$PHP_CFLAGS" \
		CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& ./configure \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--enable-option-checking=fatal \
		--with-mhash \
		--enable-ftp \
		--enable-mbstring \
		--enable-mysqlnd \
		--enable-opcache \
		--enable-calendar \
		--enable-zip \
		--enable-pdo \
		--enable-bcmath \
		--enable-exif \
		--enable-pcntl \
		--enable-soap \
		--enable-sockets \
		--enable-sysvsem \
		--enable-sysvshm \
		--with-gd \
		--with-jpeg-dir=/usr/include \
                --with-xpm-dir=/usr/include \
                --with-webp-dir=/usr/include \
                --with-png-dir=/usr/include \
                --with-freetype-dir=/usr/include \
		--with-password-argon2 \
		--with-ldap \
		--with-mysqli \
		--with-pgsql \
		--with-pdo_mysql \
		--with-pdo_pgsql \
		--with-gettext \
		--with-imap \
		--with-bz2 \
		--with-xmlrpc \
		--with-xsl \
		--with-sodium=shared \
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
		$PHP_EXTRA_CONFIGURE_ARGS \
	&& make -j "$(nproc)" \
	&& find -type f -name '*.a' -delete \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f \! -name 'docker*' -perm +0111 -exec strip --strip-all '{}' + || true; } \
	&& make clean \
	&& cp -v php.ini-* "$PHP_INI_DIR/" \
	&& cd / \
	&& docker-php-source delete \
	&& pecl update-channels \
	&& rm -rf /tmp/pear ~/.pearrc \
	&& php --version \
	&& pecl channel-update pecl.php.net \
	&& pecl install imagick \
	&& pecl install libsodium \
	&& pecl install apcu-$APCU_VERSION \
	&& pecl install apcu_bc-$APCU_BC_VERSION \
	&& docker-php-ext-enable imagick sodium apcu apc \
	&& cd / \
	&& docker-php-source delete \
	&& mv /usr/bin/envsubst /tmp/ \
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk add --no-cache --virtual .php7-rundeps $runDeps \
	&& apk del .build-php \
	&& mv /tmp/envsubst /usr/bin \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-apc.ini \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
	&& rm -rf /tmp/pear ~/.pearrc /usr/include /usr/lib/pkgconfig /usr/lib/*a /usr/share/doc /usr/share/man \
	&& rm -rf /usr/include /usr/lib/pkgconfig /usr/lib/*a /usr/share/doc /usr/share/man \
	&& rm -rf /usr/lib/*.a \
	&& chown httpd /etc/ssmtp /etc/ssmtp/ssmtp.conf \
	&& chown httpd:www /var/lib/php7/session /var/lib/php7/wsdlcache \
	&& echo mysqli.default_socket=/var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-mysqli.ini \
	&& echo pdo_mysql.default_socket = /var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini \
	&& cd /tmp \
	&& curl -LO https://composer.github.io/installer.sha384sum \
	&& curl -LO https://getcomposer.org/installer \
	&& sha3sum installer.sha384sum \
	&& php installer --filename=composer --install-dir=/usr/local/bin \
	&& rm installer installer.sha384sum \
	&& :

COPY files/php7-fpm.conf /usr/local/etc/php-fpm.conf
COPY files/php.ini-production /usr/local/etc/php.conf
COPY files/docker-entrypoint.sh /usr/local/bin
RUN chown -R httpd:www /usr/local/etc

ARG MICROSCANNER_TOKEN
RUN if [ x${MICROSCANNER_TOKEN} != x ] ; then \
	apk add --no-cache --virtual .ca ca-certificates \
	&& update-ca-certificates\
	&& wget --no-check-certificate https://get.aquasec.com/microscanner \
	&& chmod +x microscanner \
	&& ./microscanner ${MICROSCANNER_TOKEN} || exit 1\
	&& rm ./microscanner \
	&& apk del --purge .ca ;\
    fi

USER httpd
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/local/sbin/php-fpm", "--nodaemonize", "--fpm-config", "/usr/local/etc/php-fpm.conf"]
