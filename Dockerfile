FROM alpine:latest

LABEL maintainer="prakash.khadka@nepallink.net"
LABEL php_version="7.3.11"
LABEL magento_version="2.3"
LABEL description="Magento 2.3 with PHP 7.3.11"

ENV MAGENTO_VERSION 2.3
ENV INSTALL_DIR /var/www/html
ENV COMPOSER_HOME /var/www/.composer/

RUN apk update && apk upgrade
RUN apk add php7 php7-session php7-fpm php7-opcache php7-zlib php7-bcmath php7-ctype php7-ctype php7-curl php7-dom php7-gd php7-iconv php7-intl php7-mbstring php7-openssl php7-mysqli php7-simplexml php7-xmlwriter php7-tokenizer php7-xml php7-soap php7-xsl php7-zip php7-phar php7-json php7-pdo php7-pdo_mysql supervisor nginx curl

RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

COPY config/default.conf /etc/nginx/conf.d/default.conf

COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /run/nginx/
WORKDIR /var/www/html

RUN cd /tmp && \
    curl https://codeload.github.com/magento/magento2/tar.gz/$MAGENTO_VERSION -o $MAGENTO_VERSION.tar.gz \
    && tar xvf $MAGENTO_VERSION.tar.gz \
    && mv magento2-$MAGENTO_VERSION/* magento2-$MAGENTO_VERSION/.htaccess $INSTALL_DIR

RUN cd $INSTALL_DIR && composer update
RUN cd $INSTALL_DIR && composer config repositories.magento composer https://repo.magento.com/

COPY ./install-magento /usr/local/bin/install-magento
RUN chmod +x /usr/local/bin/install-magento

RUN cd $INSTALL_DIR && chown -R nginx:www-data /var/www/html/ 

RUN cd $INSTALL_DIR && find . -type f -exec chmod 644 {} \; \
    && find . -type d -exec chmod 755 {} \; \
    && find var pub/static pub/media  generated/ app/etc -type f -exec chmod g+w {} \; \
    && find var pub/static pub/media generated/ app/etc -type d -exec chmod g+ws {} \; \
    && chmod u+x bin/magento

EXPOSE 8080

COPY config/start.sh /start.sh
RUN chmod +x /start.sh

ENTRYPOINT ["/bin/sh", "/start.sh"]
