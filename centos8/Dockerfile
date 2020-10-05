#//----------------------------------------------------------------------------
#// PHP7 FastCGI Server ( for KUSANAGI Runs on Docker )
#//----------------------------------------------------------------------------
ARG OS_VERSION=8.2.2004
FROM centos:$OS_VERSION
MAINTAINER kusanagi@prime-strategy.co.jp

ENV APP_VERSION=7.4.10-1.el8

RUN : \
	&& groupadd -g 1001 www \
	&& useradd -d /var/lib/www -s /bin/nologin -g www -M -u 1001 httpd \
	&& groupadd -g 1000 kusanagi \
	&& useradd -d /home/kusanagi -s /bin/nologin -g kusanagi -G www -u 1000 -m kusanagi \
	&& chmod 755 /home/kusanagi \
    && dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
    && dnf install -y http://rpms.famillecollet.com/enterprise/remi-release-8.rpm \
    && dnf install -y https://repo.prime-strategy.co.jp/kusanagi9/rpm/kusanagi-release-9.noarch.rpm \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-prime-strategy \
    && dnf install -y kusanagi-php74-${APP_VERSION} \
    && dnf clean all \
    && rm -rf /var/cache/dnf/* \
    && chown httpd:www -R /var/opt/kusanagi \
    && sed -i -e 's|^error_log =.*$|error_log = /dev/stderr|' /etc/opt/kusanagi/php-fpm.conf \
    && sed -i -e 's|^pdo_mysql\.default_socket\s*=.*$|pdo_mysql.default_socket = /var/run/mysqld/mysqld.sock|' \
        -e 's|^mysqli\.default_socket\s*=.*$|mysqli.default_socket = /var/run/mysqld/mysqld.sock|' /etc/opt/kusanagi/php.d/php.ini \
    && sed -i -e 's|^slowlog =.*$|slowlog = /dev/stderr|' \
        -e 's|php_admin_value\[error_log\] =.*$|php_admin_value[error_log] = /dev/stderr|' /etc/opt/kusanagi/php-fpm.d/www.conf \
    && :

# COPY files/docker-entrypoint.sh /usr/local/bin
ARG MICROSCANNER_TOKEN
RUN if [ x${MICROSCANNER_TOKEN} != x ] ; then \
    	update-ca-trust \
    	&& curl -sLO https://get.aquasec.com/microscanner \
    	&& chmod +x microscanner \
    	&& ./microscanner -c ${MICROSCANNER_TOKEN} -c || exit 1 \
    	&& rm ./microscanner \
	; fi

USER httpd
# ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/opt/kusanagi/php-7.4/sbin/php-fpm", "--nodaemonize"]

