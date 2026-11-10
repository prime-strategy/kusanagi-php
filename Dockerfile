#//----------------------------------------------------------------------------
#// PHP8 FastCGI Server ( for KUSANAGI Runs on Docker )
#//----------------------------------------------------------------------------
ARG APP_VERSION=8.2.35
ARG OS_VERSION=alpine3.24

FROM --platform=$BUILDPLATFORM golang:1.26.10-${OS_VERSION} AS build-go
ARG TARGETOS TARGETARCH TARGETVARIANT
COPY files/localport_check.go /tmp
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build /tmp/localport_check.go

#//----------------------------------------------------------------------------
#// PECL extensions build stage
#//----------------------------------------------------------------------------
FROM php:${APP_VERSION}-fpm-${OS_VERSION} AS build-pecl
ARG APCU_VERSION=5.1.28
ARG PECL_YAML_VERSION=2.3.0
ARG PECL_SSH2_VERSION=1.5.0
ARG PECL_MSGPACK_VERSION=3.0.1
ARG PECL_IMAGICK_VERSION=3.8.1
ARG PECL_REDIS_VERSION=6.3.0
ARG PECL_XMLRPC_VERSION=1.0.0RC3

WORKDIR /tmp/pecl
RUN set -eux \
    && apk add --no-cache \
        $PHPIZE_DEPS \
        imagemagick-dev \
        libssh2-dev \
        libxml2-dev \
        openssl-dev \
        yaml-dev \
    && pecl channel-update pecl.php.net \
    && build_pecl() { \
        name=$1; shift; \
        for i in 1 2 3 4 5; do \
            pecl download "$name" && break; \
            [ "$i" -eq 5 ] && return 1; \
            echo "pecl download $name failed (attempt $i), retrying..."; \
            sleep $((i * 5)); \
        done \
        && tar xf "$name.tgz" \
        && (cd "$name" \
            && phpize \
            && ./configure "$@" \
            && make -j"$(getconf _NPROCESSORS_ONLN)" install ) \
        && rm -rf "$name.tgz" "$name"; \
    } \
    && build_pecl ssh2-$PECL_SSH2_VERSION \
    && build_pecl yaml-$PECL_YAML_VERSION \
    && build_pecl apcu-$APCU_VERSION \
# msgpack must be installed before redis (--enable-redis-msgpack needs its headers)
    && build_pecl msgpack-$PECL_MSGPACK_VERSION \
    && build_pecl imagick-$PECL_IMAGICK_VERSION \
    && build_pecl redis-$PECL_REDIS_VERSION --enable-redis --enable-redis-msgpack --enable-redis-lzf \
    && build_pecl xmlrpc-$PECL_XMLRPC_VERSION \
    && mkdir -p /pecl \
    && extdir="$(php-config --extension-dir)" \
    && for ext in ssh2 yaml apcu msgpack imagick redis xmlrpc; do \
        strip "$extdir/$ext.so" && cp "$extdir/$ext.so" /pecl/; \
    done

#//----------------------------------------------------------------------------
#// Core extensions build stage (runs in parallel with build-pecl)
#//----------------------------------------------------------------------------
FROM php:${APP_VERSION}-fpm-${OS_VERSION} AS build-core
RUN set -eux \
    && apk add --no-cache \
        $PHPIZE_DEPS \
        build-base \
        automake \
        gettext \
        libtool \
        mariadb-dev \
        postgresql-dev \
        gd-dev \
        gmp-dev \
        libpng-dev \
        libwebp-dev \
        libxpm-dev \
        zlib-dev \
        libzip-dev \
        freetype-dev \
        bzip2-dev \
        libexif-dev \
        pcre-dev \
        gettext-dev \
        libxslt-dev \
        openldap-dev \
        imap-dev \
        icu-dev \
        curl-dev \
        libsodium-dev \
        argon2-dev \
        coreutils \
        libjpeg-turbo-dev \
        libedit-dev \
        libxml2-dev \
        openssl-dev \
        sqlite-dev \
        libgcrypt-dev \
        libgpg-error-dev \
        tidyhtml-dev \
        libffi-dev \
    && docker-php-ext-configure gd \
        --with-webp \
        --with-jpeg \
        --with-xpm \
    && docker-php-ext-configure sockets CFLAGS="-D_GNU_SOURCE" \
    && docker-php-ext-install -j$(getconf _NPROCESSORS_ONLN) \
        mysqli \
        pgsql \
        gd \
        gmp \
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
# docker-php-ext-install strips the modules and writes docker-php-ext-*.ini
    && mkdir -p /out/conf.d \
    && cp -a "$(php-config --extension-dir)" /out/extensions \
    && cp /usr/local/etc/php/conf.d/docker-php-ext-*.ini /out/conf.d/ \
# not copied: ffi/opcache are loaded by files/20-ffi.ini and files/10-opcache.ini,
# sodium is already enabled in the base image
    && rm -f /out/conf.d/docker-php-ext-ffi.ini \
        /out/conf.d/docker-php-ext-opcache.ini \
        /out/conf.d/docker-php-ext-sodium.ini

#//----------------------------------------------------------------------------
#// Final image
#//----------------------------------------------------------------------------
FROM php:${APP_VERSION}-fpm-${OS_VERSION}
ARG  TARGETOS TARGETARCH TARGETVARIANT
LABEL maintainer=kusanagi@prime-strategy.co.jp

ARG EXTENSION_VERSION=20220829

COPY files/*.ini /usr/local/etc/php/conf.d/
COPY files/opcache*.blacklist /usr/local/etc/php.d/
COPY files/www.conf /usr/local/etc/php-fpm.d/www.conf.template
COPY files/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY files/php.ini-production /usr/local/etc/php/php.ini
COPY files/docker-entrypoint.sh /usr/local/bin
COPY --from=build-go /go/localport_check /usr/local/bin/localport_check
COPY --from=build-core /out/extensions/ /usr/local/lib/php/extensions/no-debug-non-zts-${EXTENSION_VERSION}/
COPY --from=build-core /out/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=build-pecl /pecl/*.so /usr/local/lib/php/extensions/no-debug-non-zts-${EXTENSION_VERSION}/

# add user
RUN cd /tmp \
    && apk upgrade  --no-cache \
        busybox \
        musl \
        musl-utils \
        openssl \
        zlib \
    && apk add --no-cache --virtual .user shadow \
    && groupadd -g 1001 www \
    && useradd -d /var/lib/www -s /bin/nologin -g www -M -u 1001 httpd \
    && groupadd -g 1000 kusanagi \
    && useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
    && chmod 755 /home/kusanagi \
    && apk del --purge .user \
# runtime dependencies of php, the extensions and envsubst
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' /usr/local/bin/php \
            /usr/local/sbin/php-fpm /usr/local/lib/php/extensions/no-debug-non-zts-${EXTENSION_VERSION}/*.so \
            /tmp/envsubst \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && echo $runDeps \
    && apk add --no-cache --virtual .php-rundeps $runDeps imagemagick libjpeg-turbo-utils \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/bin/envsubst \
    && docker-php-ext-enable sodium ssh2 yaml apcu msgpack imagick redis xmlrpc \
    && curl --retry 5 --retry-delay 5 --retry-all-errors -LO https://getcomposer.org/installer \
    && php installer --filename=composer --install-dir=/usr/local/bin \
    && rm installer \
    && apk del curl \
    && rm -f /usr/local/etc/php/conf.d/docker-php-ext-apc.ini \
    && rm -f /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
    && rm -f /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
    && rm -f /usr/local/etc/php/conf.d/docker-fpm.ini \
    && rm -rf /tmp/pear /usr/include /usr/lib/pkgconfig /usr/lib/*a /usr/share/doc /usr/share/man \
    && apk add --no-cache pngquant optipng jpegoptim ssmtp \
    && chown httpd /etc/ssmtp /etc/ssmtp/ssmtp.conf \
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
    && chown -R httpd:www /usr/local/etc \
    && chmod 755 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/localport_check \
    && :


USER httpd
WORKDIR /var/lib/www/
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
HEALTHCHECK --interval=10s --timeout=5s CMD /usr/local/bin/localport_check
CMD ["/usr/local/sbin/php-fpm", "--nodaemonize", "--fpm-config", "/usr/local/etc/php-fpm.conf"]
