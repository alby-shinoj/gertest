FROM debian:12.2

ENV DEBIAN_FRONTEND=noninteractive
ENV ELASTIC_VERSION=8.15.2

RUN apt-get update \
 && apt-get install -y wget curl gnupg apt-transport-https openjdk-17-jdk \
 && wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/elasticsearch.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elasticsearch.list \
 && apt-get update \
 && apt-get install -y elasticsearch=${ELASTIC_VERSION} \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/elasticsearch /var/log/elasticsearch \
 && chown -R elasticsearch:elasticsearch /usr/share/elasticsearch /etc/elasticsearch /var/lib/elasticsearch /var/log/elasticsearch

COPY elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
RUN chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.yml

USER elasticsearch

EXPOSE 9200 9300

ENV ES_PATH_CONF=/etc/elasticsearch

CMD ["/usr/share/elasticsearch/bin/elasticsearch"]
