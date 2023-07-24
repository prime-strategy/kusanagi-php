#//----------------------------------------------------------------------------
#// PHP7 FastCGI Server ( for KUSANAGI Runs on Docker )
#//----------------------------------------------------------------------------
ARG APP_VERSION=7.4.33
ARG OS_VERSION=alpine3.16
FROM --platform=$BUILDPLATFORM php:${APP_VERSION}-fpm-${OS_VERSION}
LABEL maintainer=kusanagi@prime-strategy.co.jp

# Environment variable
ARG MOZJPEG_VERSION=4.1.1
ARG APCU_VERSION=5.1.22
ARG APCU_BC_VERSION=1.0.5
ARG PECL_IMAGICK_VERSION=3.7.0
ARG PECL_MSGPACK_VERSION=2.2.0
ARG PECL_REDIS_VERSION=5.3.7
ARG PECL_SODIUM_VERSION=2.0.23
ARG PECL_SSH2_VERSION=1.4
ARG PECL_YAML_VERSION=2.2.3


ARG EXTENSION_VERSION=20190902

COPY files/*.ini /usr/local/etc/php/conf.d/
COPY files/opcache*.blacklist /usr/local/etc/php.d/
COPY files/preload.php /usr/local/etc/php.d/
COPY files/www.conf /usr/local/etc/php-fpm.d/www.conf.template
COPY files/php7-fpm.conf /usr/local/etc/php-fpm.conf
COPY files/php.ini-production /usr/local/etc/php/php.ini
COPY files/docker-entrypoint.sh /usr/local/bin

# add user
RUN : \
    && apk add --no-cache --virtual .user shadow \
    && groupadd -g 1001 www \
    && useradd -d /var/lib/www -s /bin/nologin -g www -M -u 1001 httpd \
    && groupadd -g 1000 kusanagi \
    && useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
    && chmod 755 /home/kusanagi \
    && apk del --purge .user \
    && CURL_VERSION=8.2.0-r1 \
    && OPENSSL_VERSION=1.1.1u-r2 \
    && apk add --no-cache --virtual .build-php \
        $PHPIZE_DEPS \
        build-base \
        automake \
        cmake \
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
        curl=${CURL_VERSION} \
        imagemagick \
        imagemagick-dev \
        libsodium \
        libsodium-dev \
        gettext \
        argon2-dev \
        coreutils \
        curl-dev=${CURL_VERSION} \
        libjpeg-turbo-dev \
        libedit-dev \
        libxml2-dev \
        openssl=${OPENSSL_VERSION} \
        openssl-dev=${OPENSSL_VERSION} \
        sqlite-dev \
        yaml-dev \
        libssh2-dev \
        libgcrypt-dev \
        libgpg-error-dev \
        tidyhtml-dev \
        libffi-dev \
        tar=1.34-r1 \
    && cd /tmp \
# mozjpeg
    && curl -L https://github.com/mozilla/mozjpeg/archive/v${MOZJPEG_VERSION}.tar.gz -o mozjpeg-${MOZJPEG_VERSION}.tar.gz \
    && tar xf mozjpeg-${MOZJPEG_VERSION}.tar.gz \
    && cd mozjpeg-${MOZJPEG_VERSION} \
    && mkdir build && cd build \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr -DPNG_SUPPORTED=FALSE -DWITH_MEM_SRCDST=TRUE -DWITH_JPEG8=TRUE .. \
    && make install \
    && ls -l /usr/lib/libjpeg* \
    && make -j$(getconf _NPROCESSORS_ONLN) install \
    && strip \
        /usr/bin/wrjpgcom \
        /usr/bin/rdjpgcom \
        /usr/bin/cjpeg \
        /usr/bin/jpegtran \
        /usr/bin/djpeg \
        /usr/bin/tjbench \
        /usr/lib/libturbojpeg.so.0.2.0 \
        /usr/lib/libjpeg.so.8.2.2 \
    && cp /usr/lib/libturbojpeg.so.0.2.0 \
        /usr/lib/libjpeg.so.8.2.2 \
        /tmp \
    && cp /usr/bin/mogrify /tmp \
\
# PHP7.4
\
    && pecl channel-update pecl.php.net \
    && docker-php-ext-configure gd \
        --with-webp \
        --with-jpeg \
        --with-xpm \
    && docker-php-ext-configure sockets CFLAGS="-D_GNU_SOURCE" \
    && docker-php-ext-install \
        mysqli \
        pgsql \
        opcache \
        gd \
        calendar \
        imap \
        intl \
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
    && pecl install imagick-$PECL_IMAGICK_VERSION \
    && pecl download libsodium-$PECL_SODIUM_VERSION \
    && tar xf libsodium-$PECL_SODIUM_VERSION.tgz \
    && (cd libsodium-$PECL_SODIUM_VERSION \
    && phpize \
    && ./configure \
    && make \
    && make install ) \
    && rm -rf libsodium-$PECL_SODIUM_VERSION.tgz libsodium-$PECL_SODIUM_VERSION \
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
    && docker-php-ext-enable imagick sodium ssh2 yaml apcu apc msgpack redis \
    && strip /usr/local/lib/php/extensions/no-debug-non-zts-${EXTENSION_VERSION}/*.so \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' /usr/local/bin/php \
            /usr/local/sbin/php-fpm /usr/local/lib/php/extensions/no-debug-non-zts-${EXTENSION_VERSION}/*.so \
            /tmp/mogrify /tmp/envsubst \
            | tr ',' '\n' \
            | sort -u \
            | grep -v jpeg \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk del --purge .gettext \
    && apk add --no-cache --virtual .php-rundeps $runDeps imagemagick \
    && apk del --purge .build-php \
    && mv /tmp/envsubst /usr/bin/envsubst \
    && cd / \
    && mv /tmp/mogrify /usr/bin \
    && rm -f /usr/local/etc/php/conf.d/docker-php-ext-apc.ini \
    && rm -f /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
    && rm -f /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini \
    && rm -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && rm -f /usr/local/etc/php/conf.d/docker-fpm.ini \
    && rm -rf /tmp/mozjpeg* /tmp/pear /usr/include /usr/lib/pkgconfig /usr/lib/*a /usr/share/doc /usr/share/man \
    && apk add --no-cache pngquant optipng jpegoptim ssmtp \
    && chown httpd /etc/ssmtp /etc/ssmtp/ssmtp.conf \
    && mv /tmp/libturbojpeg.so.0.2.0 /tmp/libjpeg.so.8.2.2 /usr/lib \
    && mkdir -p /var/log/php-fpm \
    && ln -sf /dev/stdout /var/log/php-fpm/www-error.log \
    && ln -sf /dev/stderr /var/log/php-fpm/www-slow.log \
    && mkdir -p /var/lib/php/session /var/lib/php/wsdlcache  \
    && chown httpd:www /var/lib/php/session /var/lib/php/wsdlcache \
    && echo mysqli.default_socket=/var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-mysqli.ini \
    && echo pdo_mysql.default_socket = /var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini \
    && cd /tmp \
    && curl -LO https://composer.github.io/installer.sha384sum \
    && curl -LO https://getcomposer.org/installer \
    && sha3sum installer.sha384sum \
    && php installer --filename=composer --install-dir=/usr/local/bin \
    && rm installer installer.sha384sum \
    && chown -R httpd:www /usr/local/etc \
    && :

RUN apk add --no-cache --virtual .curl curl \
    && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /tmp \
    && /tmp/trivy filesystem --skip-files /tmp/trivy --exit-code 1 --no-progress / \
    && apk del --purge .curl \
    && rm /tmp/trivy \
    && :

USER httpd
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/local/sbin/php-fpm", "--nodaemonize", "--fpm-config", "/usr/local/etc/php-fpm.conf"]
