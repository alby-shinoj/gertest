FROM debian:12.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y varnish \
 && rm -rf /var/lib/apt/lists/*

COPY default.vcl /etc/varnish/default.vcl

EXPOSE 6081 6082

CMD ["varnishd", "-F", "-f", "/etc/varnish/default.vcl", "-a", ":6081", "-T", ":6082", "-s", "file,/var/lib/varnish/varnish_storage.bin,1G"]
