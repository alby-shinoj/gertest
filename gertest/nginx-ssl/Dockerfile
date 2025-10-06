FROM debian:12.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y nginx openssl \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/nginx/conf.d/default.conf \
 && rm -f /etc/nginx/sites-enabled/default \
 && groupadd -g 2001 clp \
 && useradd -m -u 2000 -g clp -s /bin/bash test-ssh \
 && sed -i 's/^user .*/user test-ssh clp;/' /etc/nginx/nginx.conf

COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
