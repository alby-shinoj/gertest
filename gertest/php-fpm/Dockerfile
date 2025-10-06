FROM debian:12.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y ca-certificates apt-transport-https lsb-release curl gnupg2 \
 && curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/sury-php.list \
 && apt-get update \
 && apt-get install -y \
      php8.3-fpm php8.3-cli php8.3-common php8.3-mysql php8.3-xml php8.3-gd php8.3-intl php8.3-curl php8.3-bcmath \
      php8.3-mbstring php8.3-soap php8.3-zip php8.3-opcache php8.3-readline php8.3-simplexml php8.3-dom \
      php8.3-redis unzip git cron supervisor mariadb-client \
      libmagickwand-dev imagemagick libzip-dev libicu-dev libxml2 \
      wget gnupg ca-certificates \
 && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
 && update-alternatives --set php /usr/bin/php8.3 \
 && groupadd -g 2001 clp \
 && useradd -m -u 2000 -g clp -s /bin/bash test-ssh \
 && mkdir -p /var/www/magento /var/www/phpmyadmin \
 && wget -O /tmp/phpmyadmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz \
 && tar -xzf /tmp/phpmyadmin.tar.gz -C /var/www/phpmyadmin --strip-components=1 \
 && rm /tmp/phpmyadmin.tar.gz \
 && chown -R test-ssh:clp /var/www \
 && rm -rf /var/lib/apt/lists/*

COPY php.ini /etc/php/8.3/fpm/conf.d/99-magento.ini
COPY crontab-magento /etc/cron.d/magento
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY test-ssh.conf /etc/php/8.3/fpm/pool.d/test-ssh.conf
RUN chmod 0644 /etc/cron.d/magento \
 && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/magento

EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm8.3", "-F"]
