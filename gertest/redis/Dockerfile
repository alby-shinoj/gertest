FROM debian:12.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y redis-server \
 && rm -rf /var/lib/apt/lists/*

COPY redis.conf /etc/redis/redis.conf

VOLUME ["/data"]

EXPOSE 6379

CMD ["redis-server", "/etc/redis/redis.conf"]
