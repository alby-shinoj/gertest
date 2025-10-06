#!/bin/bash
set -e

if [ ! -f /var/www/magento/pub/health-check.php ]; then
  cat <<'PHP' > /var/www/magento/pub/health-check.php
<?php
http_response_code(200);
echo 'OK';
PHP
fi

chown -R test-ssh:clp /var/www/magento /var/www/phpmyadmin
service cron start
exec "$@"
