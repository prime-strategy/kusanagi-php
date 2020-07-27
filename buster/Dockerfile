#//----------------------------------------------------------------------------
#// PHP7 FastCGI Server ( for KUSANAGI Runs on Docker )
#//----------------------------------------------------------------------------
ARG APP_VERSION=7.4.8
ARG OS_VERSION=buster
FROM php:${APP_VERSION}-fpm-${OS_VERSION}
MAINTAINER kusanagi@prime-strategy.co.jp

# Environment variable
ARG APCU_VERSION=5.1.18
ARG APCU_BC_VERSION=1.0.5
ARG MOZJPEG_VERSION=3.3.1
ARG PECL_SODIUM_VERSION=2.0.22
ARG PECL_YAML_VERSION=2.1.0
ARG PECL_SSH2_VERSION=1.2
ARG PECL_MSGPACK_VERSION=2.1.0
ARG PECL_REDIS_VERSION=5.3.1

ARG EXTENSION_VERSION=20190902


RUN : \
	&& groupadd -g 1001 www \
	&& useradd -d /var/lib/www -s /bin/nologin -g www -M -u 1001 httpd \
	&& groupadd -g 1000 kusanagi \
	&& useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
	&& chmod 750 /home/kusanagi \
	&& pecl channel-update pecl.php.net \
    && apt-get update \
    && RUN_PKG="dbus \
        fontconfig-config \
        fonts-dejavu-core \
        fonts-droid-fallback \
        fonts-noto-mono \
        ghostscript \
        gsfonts \
        imagemagick-6-common \
        libapparmor1 \
        libavahi-client3 \
        libavahi-common-data \
        libavahi-common3 \
        libc-client2007e \
        libcups2 \
        libcupsfilters1 \
        libcupsimage2 \
        libdbus-1-3 \
        libde265-0 \
        libdigest-sha3-perl \
        libexpat1 \
        libfftw3-double3 \
        libfontconfig1 \
        libfreetype6 \
        libgs9 \
        libgs9-common \
        libheif1 \
        libidn11 \
        libijs-0.35 \
        libjbig0 \
        libjbig2dec0 \
        libjpeg62-turbo \
        liblcms2-2 \
        liblqr-1-0 \
        libltdl7 \
        libmagickcore-6.q16-6 \
        libmagickwand-6.q16-6 \
        libnuma1 " \
    && DEV_PKG="automake \
        autotools-dev \
        cmake \
        comerr-dev \
        fontconfig \
        gettext \
        gettext-base \
        gir1.2-freedesktop \
        gir1.2-gdkpixbuf-2.0 \
        gir1.2-glib-2.0 \
        gir1.2-rsvg-2.0 \
        icu-devtools \
        javascript-common \
        jpegoptim \
        krb5-multidev \
        libblkid-dev \
        libbz2-dev \
        libc-client2007e-dev \
        libcairo-gobject2 \
        libcairo-script-interpreter2 \
        libcairo2 \
        libcairo2-dev \
        libcap2 \
        libcroco3 \
        libdatrie1 \
        libdjvulibre-dev \
        libdjvulibre-text \
        libdjvulibre21 \
        libelf1 \
        libexif-dev \
        libexif-doc \
        libexif12 \
        libexpat1-dev \
        libffi-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libfribidi0 \
        libgcrypt20-dev \
        libgdk-pixbuf2.0-0 \
        libgdk-pixbuf2.0-bin \
        libgdk-pixbuf2.0-common \
        libgdk-pixbuf2.0-dev \
        libgirepository-1.0-1 \
        libglib2.0-bin \
        libglib2.0-data \
        libglib2.0-dev \
        libglib2.0-dev-bin \
        libgpg-error-dev \
        libgraphite2-3 \
        libgssrpc4 \
        libharfbuzz0b \
        libice-dev \
        libice6 \
        libicu-dev \
        libilmbase-dev \
        libilmbase23 \
        libimagequant0 \
        libjbig-dev \
        libjpeg-dev \
        libjpeg62-turbo-dev \
        libjs-jquery \
        libjxr-tools \
        libjxr0 \
        libkadm5clnt-mit11 \
        libkadm5srv-mit11 \
        libkdb5-9 \
        libkrb5-dev \
        liblcms2-dev \
        libldap2-dev \
        liblqr-1-0-dev \
        libltdl-dev \
        libltdl-dev \
        liblzma-dev \
        liblzo2-2 \
        libmagickcore-6-arch-config \
        libmagickcore-6-headers \
        libmagickcore-6.q16-6-extra \
        libmagickcore-6.q16-dev \
        libmagickwand-6-headers \
        libmagickwand-6.q16-dev \
        libmount-dev \
        libmpdec2 \
        libopenexr-dev \
        libopenexr23 \
        libopenjp2-7-dev \
        libpam0g-dev \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libpangoft2-1.0-0 \
        libpaper-utils \
        libpcre16-3 \
        libpcre3-dev \
        libpcre32-3 \
        libpcrecpp0v5 \
        libpixman-1-0 \
        libpixman-1-dev \
        libpng-dev \
        libpng-tools \
        libpq-dev \
        libpthread-stubs0-dev \
        libpython3-stdlib \
        libpython3.7-minimal \
        libpython3.7-stdlib \
        libreadline7 \
        librsvg2-2 \
        librsvg2-common \
        librsvg2-dev \
        libselinux1-dev \
        libsepol1-dev \
        libsm-dev \
        libsm6 \
        libssh2-1-dev \
        libssl-dev \
        libthai-data \
        libthai0 \
        libtidy-dev \
        libtiff-dev \
        libtiffxx5 \
        libtool \
        libwebp-dev \
        libwmf-dev \
        libwmf0.2-7 \
        libx11-dev \
        libxau-dev \
        libxcb-render0 \
        libxcb-render0-dev \
        libxcb-shm0 \
        libxcb-shm0-dev \
        libxcb1-dev \
        libxdmcp-dev \
        libxext-dev \
        libxml2-dev \
        libxpm-dev \
        libxrender-dev \
        libxrender1 \
        libxslt1-dev \
        libxt-dev \
        libxt6 \
        libyaml-dev \
        libzip-dev \
        mime-support \
        pax-utils \
        python3 \
        python3-distutils \
        python3-lib2to3 \
        python3-minimal \
        python3.7 \
        python3.7-minimal \
        readline-common \
        shared-mime-info \
        uuid-dev \
        x11proto-core-dev \
        x11proto-dev \
        x11proto-xext-dev \
        xorg-sgml-doctools \
        xtrans-dev \
        yasm \
        zlib1g-dev" \
    && apt-get -y install $RUN_PKG $DEV_PKG \
    # mozjpeg
    && cd /tmp \
	&& curl -LO https://github.com/mozilla/mozjpeg/archive/v${MOZJPEG_VERSION}.tar.gz#//mozjpeg-${MOZJPEG_VERSION}.tar.gz \
	&& tar xf mozjpeg-${MOZJPEG_VERSION}.tar.gz \
	&& cd mozjpeg-${MOZJPEG_VERSION} \
	&& autoreconf -fiv \
	&& mkdir build && cd build \
	&& sh ../configure --with-jpeg8 --prefix=/usr \
    && make -j $(nproc) install \
    && cd /tmp \
	&& strip \ 
		/usr/bin/wrjpgcom \
		/usr/bin/rdjpgcom \
		/usr/bin/cjpeg \
		/usr/bin/jpegtran \
		/usr/bin/djpeg \
		/usr/bin/tjbench \
		/usr/lib/libturbojpeg.so.0.1.0 \
		/usr/lib/libjpeg.so.8.1.2 \
    && cp \
		/usr/bin/wrjpgcom \
		/usr/bin/rdjpgcom \
		/usr/bin/cjpeg \
		/usr/bin/jpegtran \
		/usr/bin/djpeg \
		/usr/bin/tjbench \
		/usr/lib/libturbojpeg.so.0.1.0 \
		/usr/lib/libjpeg.so.8.1.2 \
        /tmp \
	&& docker-php-ext-configure gd \
		--with-webp \
		--with-jpeg \
		--with-xpm \
	&& docker-php-ext-configure imap \
        --with-kerberos \
        --with-imap-ssl \
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
		tidy \
        ffi \
	&& pecl install imagick \
	&& pecl download ssh2-$PECL_SSH2_VERSION \
	&& tar xf ssh2-$PECL_SSH2_VERSION.tgz \
	&& (cd ssh2-$PECL_SSH2_VERSION \
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
	&& docker-php-ext-enable imagick ssh2 yaml apcu apc msgpack redis \
	&& strip /usr/local/lib/php/extensions/no-debug-non-zts-${EXTENSION_VERSION}/*.so \
	&& cp /usr/bin/envsubst /tmp/ \
    && apt remove -y $DEV_PKG \
    && mv /tmp/envsubst /usr/bin \
    && mv \
		/tmp/wrjpgcom \
		/tmp/rdjpgcom \
		/tmp/cjpeg \
		/tmp/jpegtran \
		/tmp/djpeg \
		/tmp/tjbench \
        /usr/bin \
    && mv \
		/tmp/libturbojpeg.so.0.1.0 \
		/tmp/libjpeg.so.8.1.2 \
        /usr/lib \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-apc.ini \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
	&& rm -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
	&& rm -rf /tmp/mozjpeg* /tmp/pear \
	&& mkdir -p /etc/php7.d/conf.d /etc/php7-fpm.d \
	&& cp /usr/local/etc/php/conf.d/* /etc/php7.d/conf.d/ \
	&& cp /usr/local/etc/php-fpm.d/* /etc/php7-fpm.d/ \
	&& mkdir -p /var/log/php7-fpm \
	&& ln -sf /dev/stdout /var/log/php7-fpm/www-error.log \
	&& ln -sf /dev/stderr /var/log/php7-fpm/www-slow.log \
	&& mkdir -p /var/lib/php7/session /var/lib/php7/wsdlcache  \
	&& chown httpd:www /var/lib/php7/session /var/lib/php7/wsdlcache \
	&& echo mysqli.default_socket=/var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-mysqli.ini \
	&& echo pdo_mysql.default_socket = /var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini \
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
	update-ca-certificates \
	&& curl -sLO https://get.aquasec.com/microscanner \
	&& chmod +x microscanner \
	&& ./microscanner ${MICROSCANNER_TOKEN} || exit 1\
    && rm ./microscanner ; \
    fi

USER httpd
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/local/sbin/php-fpm", "--nodaemonize", "--fpm-config", "/usr/local/etc/php-fpm.conf"]
