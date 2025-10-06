FROM debian:12.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y wget gnupg lsb-release ca-certificates \
 && wget -O /tmp/mysql-apt-config.deb https://repo.mysql.com/mysql-apt-config_0.8.29-1_all.deb \
 && dpkg -i /tmp/mysql-apt-config.deb \
 && rm /tmp/mysql-apt-config.deb \
 && apt-get update \
 && apt-get install -y mysql-server pwgen \
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /var/run/mysqld \
 && chown mysql:mysql /var/run/mysqld \
 && mkdir -p /docker-entrypoint-initdb.d

COPY init-db.sh /usr/local/bin/init-db.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/init-db.sh /usr/local/bin/docker-entrypoint.sh

VOLUME ["/var/lib/mysql"]

EXPOSE 3306

HEALTHCHECK CMD mysqladmin ping -h 127.0.0.1 || exit 1

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["mysqld", "--user=mysql"]
