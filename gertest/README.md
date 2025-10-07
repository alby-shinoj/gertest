# Magento 2 Container Stack (Debian 12.2)

A reproducible Magento 2.4.8-p2 environment featuring HTTPS termination, Varnish full-page cache, Redis-backed sessions/cache, Elasticsearch 8.15 search, and phpMyAdmin — all orchestrated with Docker Compose. This README is a complete runbook: follow it end-to-end to build, operate, and troubleshoot the stack. For a deeper narrative, see `docs/full-guide.md`.

---

## 1. Prerequisites
- Docker Engine >= 24.0 with Compose plugin >= 2.0
- 4+ vCPU, 8+ GB RAM, 30+ GB free disk
- POSIX shell, `curl`, `openssl`
- Ability to edit `/etc/hosts`

> **Optional:** Install `jq` for improved JSON inspection.

---

## 2. Repository Layout
```
|-- docker-compose.yml      # Service topology and volumes
|-- nginx-ssl/              # HTTPS edge proxy (TLS certs, proxy config)
|-- varnish/                # Magento-generated VCL and varnish image
|-- nginx-backend/          # Origin nginx serving Magento + phpMyAdmin
|-- php-fpm/                # PHP 8.3 FPM image, cron, Composer, sample data
|-- mysql/                  # MySQL 8.0 image and init scripts
|-- redis/                  # Redis 7 config
|-- elasticsearch/          # Elasticsearch 8.15 image + config
|-- docs/full-guide.md     # Comprehensive documentation
|-- gencert.sh              # SAN cert generation helper (test/pma domains)
`-- install_docker_kali.sh  # Helper for Kali-based host installs
```
Use `docs/full-guide.md` for an expanded explanation of every file and workflow.

---

## 3. One-Time Host Preparation
1. **Clone repo**
   ```bash
   git clone <repo-url> gertest && cd gertest
   ```
2. **Generate SAN certificate** (self-signed placeholder)
   ```bash
   docker run --rm -v $(pwd)/nginx-ssl/certs:/certs \
     -v $(pwd)/gencert.sh:/gencert.sh alpine sh /gencert.sh
   ```
   *Outputs `selfsigned.crt` and `selfsigned.key` covering `test.mgt.com` + `pma.mgt.com`.*
3. **Add hostnames**
   ```bash
   printf '127.0.0.1 test.mgt.com\n127.0.0.1 pma.mgt.com\n' | sudo tee -a /etc/hosts
   ```

> Replace the generated certificate with a real CA-issued cert before exposing the stack outside a lab.

---

## 4. Build & Launch
1. **Build custom images**
   ```bash
   docker compose build
   ```
2. **Start services**
   ```bash
   docker compose up -d
   ```
   Wait until `docker compose ps` shows all services as `Up` (health checks report `healthy` for MySQL, Redis, Elasticsearch, nginx-backend).

3. **Verify baseline**
   ```bash
   docker compose ps
   docker compose exec php-fpm php -v         # PHP 8.3.26
   docker compose exec elasticsearch curl -s http://localhost:9200/_cluster/health?pretty
   docker compose exec php-fpm bash -lc 'cd /var/www/magento && php bin/magento --version'
   ```

Magento and sample data are already installed within the shared volume. If starting from a clean volume, repeat the installation steps described in §6.3.

---

## 5. Runtime Architecture
```
Browser (HTTPS)
   |
   v
nginx-ssl (edge TLS, 80/443)
   |-- `test.mgt.com` -> varnish (6081)
   |         `-- nginx-backend:8080 -> php-fpm:9000 -> Magento (Redis, MySQL, Elasticsearch)
   `-- pma.mgt.com`  -> nginx-backend:8081 -> phpMyAdmin -> MySQL
```
- `php-fpm` runs as user `test-ssh:clp`, auto-creates `pub/health-check.php`, and starts cron jobs.
- Magento cache + session storage leverage Redis DB0/DB1/DB2. Full-page cache is Varnish-backed.
- Elasticsearch 8.15 provides catalog search; security is disabled for local development.

---

## 6. Operational Tasks
### 6.1 Day-to-Day Commands
| Action                             | Command |
|------------------------------------|---------|
| Start stack                        | `docker compose up -d` |
| Stop stack                         | `docker compose down` |
| Follow logs per service            | `docker compose logs -f <service>` |
| Access Magento CLI                 | `docker compose exec php-fpm bash -lc 'cd /var/www/magento && php bin/magento ...'` |
| Flush cache                        | `... php bin/magento cache:flush` |
| Reindex                            | `... php bin/magento indexer:reindex` |
| Deploy static content              | `... php bin/magento setup:static-content:deploy -f en_US` |
| Run cron manually                  | `... php bin/magento cron:run` |

### 6.2 Magento Reinstall (if clean volume)
```bash
docker compose exec php-fpm bash -lc '
  cd /var/www/magento && \
  php bin/magento module:enable Magento_SampleData Magento_CatalogSampleData ... && \
  php bin/magento setup:upgrade && \
  php bin/magento setup:di:compile && \
  php bin/magento setup:static-content:deploy -f en_US && \
  php bin/magento config:show web/secure/base_url
'
```
Ensure `core_config_data` reflects HTTPS URLs, Elasticsearch (`elasticsearch8`), and varnish FPC ID 2. Preconfigured values are populated in this repository build.

### 6.3 Backups
1. Stop stack: `docker compose down`.
2. Export volumes:
   ```bash
   for vol in magento-app phpmyadmin-app mysql-data redis-data elasticsearch-data varnish-cache; do
     docker run --rm -v gertest_${vol}:/volume -v $(pwd):/backup \
       debian:12.2 tar -czf /backup/${vol}.tar.gz -C /volume .
   done
   ```
3. Optional: `docker save` images tagged `m2-*` for offline reuse.

---

## 7. Verification Checklist
Run these after `docker compose up -d` or any major change:

1. **Service health**
   ```bash
   docker compose ps
   ```
2. **PHP runtime** – `docker compose exec php-fpm php -v`
3. **Magento CLI** – `php bin/magento --version`
4. **Base URLs & cache engine**
   ```bash
   docker compose exec php-fpm bash -lc 'cd /var/www/magento && \
     php bin/magento config:show web/secure/base_url && \
     php bin/magento config:show catalog/search/engine && \
     php bin/magento config:show system/full_page_cache/caching_application'
   ```
5. **Elasticsearch health** – `docker compose exec elasticsearch curl -s http://localhost:9200/_cluster/health?pretty`
6. **Redis usage** – `docker compose exec redis redis-cli info keyspace`
7. **HTTPS endpoints**
   ```bash
   curl -kI https://127.0.0.1/ -H 'Host: test.mgt.com'
   curl -kI https://127.0.0.1/ -H 'Host: pma.mgt.com'
   ```
8. **Cron logs** – ensure `/var/www/magento/var/log/*cron.log` are empty after manual `cron:run`.

All checks passing -> stack is production-complete within lab constraints.

---

## 8. Troubleshooting Guide
| Symptom | Cause | Fix |
|---------|-------|-----|
| 502 from nginx-ssl | varnish or backend unhealthy | `docker compose restart php-fpm nginx-backend varnish nginx-ssl`
| Elasticsearch `yellow` | replica shards on single node | `PUT /_all/_settings {"index":{"number_of_replicas":0}}`
| Redis connection refused | Redis container down | `docker compose restart redis`
| Magento CLI missing DOM/SimpleXML | Wrong PHP alternative active | `update-alternatives --set php /usr/bin/php8.3`
| Cron logs show `www-data not found` | Cron user mis-set | Ensure `/etc/cron.d/magento` lists `test-ssh`; rebuild PHP image
| TLS errors | Cert mismatch or browser distrust | Replace cert in `nginx-ssl/certs`; import to OS trust store

See `docs/full-guide.md` for expanded troubleshooting, queue consumer tips, and scaling strategies.

---

## 9. Maintenance Tips
- Regenerate SAN certificate annually (`gencert.sh`).
- Monitor disk usage of named volumes (`docker system df`, `docker volume inspect`).
- Keep images up to date: `docker compose build --pull`.
- Replace self-signed cert with production-ready certificates before external exposure.
- For automation, wrap key commands in `Makefile` targets (e.g., `make up`, `make down`, `make logs`).

---

## 10. Additional Resources
- Magento dev docs: https://developer.adobe.com/commerce
- Elasticsearch reference: https://www.elastic.co/guide/index.html
- Redis docs: https://redis.io/documentation

---
