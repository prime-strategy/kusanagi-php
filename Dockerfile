#//----------------------------------------------------------------------------
#// PHP7 FastCGI Server ( for KUSANAGI Runs on Docker )
#//----------------------------------------------------------------------------
ARG APP_VERSION=7.3.13
ARG OS_VERSION=alpine3.10
FROM php:${APP_VERSION}-fpm-${OS_VERSION}
MAINTAINER kusanagi@prime-strategy.co.jp

# Environment variable
ARG APCU_VERSION=5.1.18
ARG APCU_BC_VERSION=1.0.5
ARG MOZJPEG_VERSION=3.3.1
ARG PECL_YAML_VERSION=2.0.4
ARG PECL_SSH2_VERSION=1.1.2
ARG PECL_MSGPACK_VERSION=2.0.3
ARG PECL_REDIS_VERSION=5.0.2

ARG EXTENSION_VERSION=20180731

# add user
RUN : \
	&& apk update \
	&& apk upgrade \
	&& apk add --virtual .user shadow \
	&& groupadd -g 1001 www \
	&& useradd -d /var/lib/www -s /bin/nologin -g www -M -u 1001 httpd \
	&& groupadd -g 1000 kusanagi \
	&& useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
	&& chmod 755 /home/kusanagi \
	&& apk del --purge .user \
	&& :

COPY files/remi_ssh2_php7_a8835aab2c15e794fce13bd927295719e384ad2d.patch /tmp/remi_ssh2_php7_1.patch
COPY files/remi_ssh2_php7_073067ba96ac99ed5696d27f13ca6c8124986e74.patch /tmp/remi_ssh2_php7_2.patch

RUN apk update \
	&& apk add --update --no-cache --virtual .build-php \
		$PHPIZE_DEPS \
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
		sqlite-dev \
		yaml-dev \
		libssh2-dev \
	&& cd /tmp \
# mozjpeg
	&& curl -LO https://github.com/mozilla/mozjpeg/archive/v${MOZJPEG_VERSION}.tar.gz#//mozjpeg-${MOZJPEG_VERSION}.tar.gz \
	&& tar xf mozjpeg-${MOZJPEG_VERSION}.tar.gz \
	&& cd mozjpeg-${MOZJPEG_VERSION} \
	&& autoreconf -fiv \
	&& mkdir build && cd build \
	&& sh ../configure --with-jpeg8 --prefix=/usr \
	&& make -j$(getconf _NPROCESSORS_ONLN) install \
	&& strip \
		/usr/bin/wrjpgcom \
		/usr/bin/rdjpgcom \
		/usr/bin/cjpeg \
		/usr/bin/jpegtran \
		/usr/bin/djpeg \
		/usr/bin/tjbench \
		/usr/lib/libturbojpeg.so.0.1.0 \
		/usr/lib/libjpeg.so.8.1.2 \
	&& cp /usr/lib/libturbojpeg.so.0.1.0 \
		/usr/lib/libjpeg.so.8.1.2 \
		/tmp \
	&& cp /usr/bin/mogrify /tmp \
\
# PHP7.3
\
	&& pecl channel-update pecl.php.net \
	&& docker-php-ext-configure gd --with-jpeg-dir=/usr/include \
		--with-xpm-dir=/usr/include --with-webp-dir=/usr/include \
		--with-png-dir=/usr/include --with-freetype-dir=/usr/include/ \
	&& docker-php-ext-install \
		mysqli \
		pgsql \
		opcache \
		gd \
		calendar \
		imap \
		ldap \
		bz2 \
		zip \
		pdo \
		pdo_mysql \
		pdo_pgsql \
		bcmath \
		exif \
		gettext \
		pcntl \
		soap \
		sockets \
		sysvsem \
		sysvshm \
		xmlrpc \
		xsl \
	&& pecl install imagick \
	&& pecl install libsodium \
	&& pecl download ssh2-$PECL_SSH2_VERSION \
	&& tar xf ssh2-$PECL_SSH2_VERSION.tgz \
	&& (cd ssh2-$PECL_SSH2_VERSION \
	&& patch -p1 < /tmp/remi_ssh2_php7_1.patch \
	&& patch -p1 < /tmp/remi_ssh2_php7_2.patch \
	&& phpize \ 
	&& ./configure \
	&& make \
	&& make install ) \
	&& rm -rf ssh2-$PECL_SSH2_VERSION.tgz ssh2-$PECL_SSH2_VERSION \
	&& pecl install yaml-$PECL_YAML_VERSION \
	&& pecl install apcu-$APCU_VERSION \
	&& pecl install apcu_bc-$APCU_BC_VERSION \
	&& pecl install msgpack-$PECL_MSGPACK_VERSION \
	&& pecl download redis-$PECL_REDIS_VERSION \
	&& tar xf redis-$PECL_REDIS_VERSION.tgz \
	&& (cd redis-$PECL_REDIS_VERSION \
	&& phpize \
	&& ./configure  --enable-redis --enable-redis-msgpack --enable-redis-lzf \
	&& make \
	&& make install )\
	&& rm -rf redis-$PECL_REDIS_VERSION.tgz redis-$PECL_REDIS_VERSION \
	&& docker-php-source delete \
	&& docker-php-ext-enable imagick sodium ssh2 yaml apcu apc msgpack redis \
	&& strip /usr/local/lib/php/extensions/no-debug-non-zts-${EXTENSION_VERSION}/*.so \
	&& apk add --no-cache --virtual .gettext gettext \
	&& mv /usr/bin/envsubst /tmp/ \
	&& runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' /usr/local/bin/php /tmp/mogriify \
			/usr/local/lib/php/extensions/no-debug-non-zts-${EXTENSION_VERSION}/*.so /tmp/envsubst \
			| tr ',' '\n' \
			| sort -u \
			| grep -v jpeg \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)" \
	&& apk del .gettext \
	&& apk add --no-cache --virtual .php-rundeps $runDeps \
	&& apk del .build-php \
	&& mv /tmp/envsubst /usr/bin/envsubst \
	&& cd / \
	&& mv /tmp/mogrify /usr/bin \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-apc.ini \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
	&& rm -rf /tmp/mozjpeg* /tmp/pear /usr/include /usr/lib/pkgconfig /usr/lib/*a /usr/share/doc /usr/share/man \
	&& apk add pngquant optipng jpegoptim ssmtp \
	&& chown httpd /etc/ssmtp /etc/ssmtp/ssmtp.conf \
	&& mv /tmp/libturbojpeg.so.0.1.0 /tmp/libjpeg.so.8.1.2 /usr/lib \
	&& mkdir -p /etc/php7.d/conf.d /etc/php7-fpm.d \
	&& cp /usr/local/etc/php/conf.d/* /etc/php7.d/conf.d/ \
	&& cp /usr/local/etc/php-fpm.d/* /etc/php7-fpm.d/ \
	&& mkdir -p /var/log/php7-fpm \
	&& ln -sf /dev/stdout /var/log/php7-fpm/www-error.log \
	&& ln -sf /dev/stderr /var/log/php7-fpm/www-slow.log \
	&& :

RUN	mkdir -p /var/lib/php7/session /var/lib/php7/wsdlcache  \
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

COPY files/*.ini /usr/local/etc/php/conf.d/
COPY files/opcache*.blacklist /usr/local/etc/php.d/
COPY files/www.conf /usr/local/etc/php-fpm.d/www.conf.template
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
	&& ./microscanner ${MICROSCANNER_TOKEN} || exit 1 \
	&& rm ./microscanner \
	&& apk del --purge .ca ;\
	fi

USER httpd
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/local/sbin/php-fpm", "--nodaemonize", "--fpm-config", "/usr/local/etc/php-fpm.conf"]
