FROM debian:12.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y nginx curl \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/nginx/sites-enabled/default

COPY magento.conf /etc/nginx/sites-available/magento.conf
COPY phpmyadmin.conf /etc/nginx/sites-available/phpmyadmin.conf

RUN groupadd -g 2001 clp \
 && useradd -m -u 2000 -g clp -s /bin/bash test-ssh \
 && sed -i 's/^user .*/user test-ssh clp;/' /etc/nginx/nginx.conf \
 && ln -s /etc/nginx/sites-available/magento.conf /etc/nginx/sites-enabled/magento.conf \
 && ln -s /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf

EXPOSE 8080 8081

CMD ["nginx", "-g", "daemon off;"]
