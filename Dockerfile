#//----------------------------------------------------------------------------
#// PHP8 FastCGI Server ( for KUSANAGI Runs on Docker )
#//----------------------------------------------------------------------------
ARG APP_VERSION=8.1.26
ARG OS_VERSION=alpine3.18
FROM --platform=$BUILDPLATFORM php:${APP_VERSION}-fpm-${OS_VERSION}
LABEL maintainer=kusanagi@prime-strategy.co.jp


# Environment variable
ARG APCU_VERSION=5.1.23
ARG MOZJPEG_VERSION=4.1.1
ARG PECL_SODIUM_VERSION=2.0.23
ARG PECL_YAML_VERSION=2.2.3
ARG PECL_SSH2_VERSION=1.4
ARG PECL_MSGPACK_VERSION=2.2.0
ARG PECL_IMAGICK_VERSION=3.7.0
ARG PECL_REDIS_VERSION=6.0.2
ARG PECL_XMLRPC_VERSION=1.0.0RC3

ARG EXTENSION_VERSION=20210902

COPY files/*.ini /usr/local/etc/php/conf.d/
COPY files/opcache*.blacklist /usr/local/etc/php.d/
COPY files/preload.php /usr/local/etc/php.d/
COPY files/www.conf /usr/local/etc/php-fpm.d/www.conf.template
COPY files/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY files/php.ini-production /usr/local/etc/php/php.ini
COPY files/docker-entrypoint.sh /usr/local/bin

WORKDIR /tmp
# add user
RUN : \
    && apk add --no-cache --virtual .user shadow \
    && groupadd -g 1001 www \
    && useradd -d /var/lib/www -s /bin/nologin -g www -M -u 1001 httpd \
    && groupadd -g 1000 kusanagi \
    && useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
    && chmod 755 /home/kusanagi \
    && CURL_VERSIOH=8.4.0-r0 \
    && OPENSSL_VERSION=3.1.4-r1 \
    && apk del --purge .user \
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
        imagemagick \
        imagemagick-dev \
        libsodium \
        libsodium-dev \
        gettext \
        argon2-dev \
        coreutils \
        curl=${CURL_VERSIOH} \
        curl-dev=${CURL_VERSIOH} \
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
        tar \
    && curl -L https://github.com/mozilla/mozjpeg/archive/v${MOZJPEG_VERSION}.tar.gz  -o mozjpeg-${MOZJPEG_VERSION}.tar.gz \
    && tar xf mozjpeg-${MOZJPEG_VERSION}.tar.gz \
    && (cd  mozjpeg-${MOZJPEG_VERSION} \
        && (mkdir build && cd  build \
            && cmake -DCMAKE_INSTALL_PREFIX=/usr -DPNG_SUPPORTED=FALSE -DWITH_MEM_SRCDST=TRUE .. \
            && make -j$(getconf _NPROCESSORS_ONLN) install ) \
        && ls -l /usr/lib/libjpeg* \
        && strip \
            /usr/bin/wrjpgcom \
            /usr/bin/rdjpgcom \
            /usr/bin/cjpeg \
            /usr/bin/jpegtran \
            /usr/bin/djpeg \
            /usr/bin/tjbench \
            /usr/lib64/libturbojpeg.so.0.2.0 \
            /usr/lib64/libjpeg.so.62.3.0 \
        && cp /usr/lib64/libturbojpeg.so.0.2.0 \
            /usr/lib64/libjpeg.so.62.3.0 \
            /usr/bin/mogrify \
            /tmp )\
\
    && pecl channel-update pecl.php.net \
    && pecl install apcu-$APCU_VERSION \
    && docker-php-ext-enable apcu \
    && docker-php-ext-configure gd \
        --with-webp \
        --with-jpeg \
        --with-xpm \
    && docker-php-ext-configure sockets CFLAGS="-D_GNU_SOURCE" \
    && docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) \
        mysqli \
        pgsql \
        gd \
        opcache \
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
        xsl \
        tidy \
        ffi \
    && pecl download libsodium-$PECL_SODIUM_VERSION \
    && tar xf libsodium-$PECL_SODIUM_VERSION.tgz \
    && (cd  libsodium-$PECL_SODIUM_VERSION \
        && phpize \
        && ./configure \
        && make -j$(getconf _NPROCESSORS_ONLN) install ) \
    && rm -rf libsodium-$PECL_SODIUM_VERSION.tgz libsodium-$PECL_SODIUM_VERSION \
    && pecl download ssh2-$PECL_SSH2_VERSION \
    && tar xf ssh2-$PECL_SSH2_VERSION.tgz \
    && (cd  ssh2-$PECL_SSH2_VERSION \
        && phpize \
        && ./configure \
        && make -j$(getconf _NPROCESSORS_ONLN) install ) \
    && rm -rf ssh2-$PECL_SSH2_VERSION.tgz ssh2-$PECL_SSH2_VERSION \
    && pecl download yaml-$PECL_YAML_VERSION \
    && tar xf yaml-$PECL_YAML_VERSION.tgz \
    && (cd yaml-$PECL_YAML_VERSION \
        && phpize \
        && ./configure \
        && make -j$(getconf _NPROCESSORS_ONLN) install ) \
    && rm -rf yaml-$PECL_YAML_VERSION.tgz yaml-$PECL_YAML_VERSION \
    && pecl download msgpack-$PECL_MSGPACK_VERSION \
    && tar xf msgpack-$PECL_MSGPACK_VERSION.tgz \
    && (cd msgpack-$PECL_MSGPACK_VERSION \
        && phpize \
        && ./configure \
        && make -j$(getconf _NPROCESSORS_ONLN) install ) \
    && rm -rf msgpack-$PECL_MSGPACK_VERSION.tgz msgpack-$PECL_MSGPACK_VERSION \
    && pecl download imagick-$PECL_IMAGICK_VERSION \
    && tar xf imagick-$PECL_IMAGICK_VERSION.tgz \
    && (cd imagick-$PECL_IMAGICK_VERSION \
        && phpize \
        && ./configure \
        && make -j$(getconf _NPROCESSORS_ONLN) install ) \
    && rm -rf imagick-$PECL_IMAGICK_VERSION.tgz imagick-$PECL_IMAGICK_VERSION \
    && pecl download redis-$PECL_REDIS_VERSION \
    && tar xf redis-$PECL_REDIS_VERSION.tgz \
    && (cd  redis-$PECL_REDIS_VERSION \
        && phpize \
        && ./configure  --enable-redis --enable-redis-msgpack --enable-redis-lzf \
        && make -j$(getconf _NPROCESSORS_ONLN) install ) \
    && rm -rf redis-$PECL_REDIS_VERSION.tgz redis-$PECL_REDIS_VERSION \
    && pecl download xmlrpc-$PECL_XMLRPC_VERSION \
    && tar xf xmlrpc-$PECL_XMLRPC_VERSION.tgz \
    && (cd  xmlrpc-$PECL_XMLRPC_VERSION \
        && phpize \
        && ./configure \
        && make -j$(getconf _NPROCESSORS_ONLN) install ) \
    && rm -rf xmlrpc-$PECL_XMLRPC_VERSION.tgz xmlrpc-$PECL_XMLRPC_VERSION \
    && docker-php-ext-enable sodium ssh2 yaml msgpack imagick redis xmlrpc \
    && docker-php-source delete \
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
    && echo $runDeps \
    && apk add --no-cache --virtual .php-rundeps $runDeps imagemagick \
    && apk del --purge .build-php \
    && mv /tmp/envsubst /usr/bin/envsubst \
    && mv /tmp/mogrify /usr/bin \
    && rm -f /usr/local/etc/php/conf.d/docker-php-ext-apc.ini \
             /usr/local/etc/php/conf.d/docker-php-ext-ffi.ini \
             /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
             /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
             /usr/local/etc/php/conf.d/docker-fpm.ini \
    && rm -rf /tmp/mozjpeg* /tmp/pear /usr/include /usr/lib/pkgconfig /usr/lib/*a /usr/share/doc /usr/share/man \
    && apk add --no-cache pngquant optipng jpegoptim ssmtp \
    && chown httpd /etc/ssmtp /etc/ssmtp/ssmtp.conf \
    && mv /tmp/libturbojpeg.so.0.2.0 /tmp/libjpeg.so.62.3.0 /usr/lib64 \
    && mkdir -p /etc/php.d/conf.d /etc/php-fpm.d \
    && cp /usr/local/etc/php/conf.d/* /etc/php.d/conf.d/ \
    && cp /usr/local/etc/php-fpm.d/* /etc/php-fpm.d/ \
    && mkdir -p /var/log/php-fpm \
    && ln -sf /dev/stdout /var/log/php-fpm/www-error.log \
    && ln -sf /dev/stderr /var/log/php-fpm/www-slow.log \
    && mkdir -p /var/lib/php/session /var/lib/php/wsdlcache  \
    && chown httpd:www /var/lib/php/session /var/lib/php/wsdlcache \
    && echo mysqli.default_socket=/var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-mysqli.ini \
    && echo pdo_mysql.default_socket = /var/run/mysqld/mysqld.sock >> /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini \
    && curl -LO https://composer.github.io/installer.sha384sum \
    && curl -LO https://getcomposer.org/installer \
    && sha3sum installer.sha384sum \
    && php installer --filename=composer --install-dir=/usr/local/bin \
    && rm installer installer.sha384sum \
    && chown -R httpd:www /usr/local/etc \
    && :

RUN apk add --no-cache --virtual .curl curl \
    && curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/master/contrib/install.sh | sh -s -- -b /tmp \
    && /tmp/trivy filesystem --skip-files /tmp/trivy --exit-code 1 --no-progress / \
    && apk del .curl \
    && rm /tmp/trivy \
    && :

USER httpd
WORKDIR /var/lib/www/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
HEALTHCHECK --interval=10s --timeout=5s CMD netstat -ltn| grep 9000 > /dev/null || exit 1
CMD ["/usr/local/sbin/php-fpm", "--nodaemonize", "--fpm-config", "/usr/local/etc/php-fpm.conf"]
