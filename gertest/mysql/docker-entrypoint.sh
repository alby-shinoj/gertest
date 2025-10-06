#!/bin/bash
set -e

if [ "${1:0:1}" = '-' ]; then
  set -- mysqld "$@"
fi

if [ "$1" = 'mysqld' ]; then
  DATADIR="/var/lib/mysql"
  if [ ! -d "$DATADIR/mysql" ]; then
    echo "Initializing MySQL data directory"
    mkdir -p "$DATADIR"
    chown -R mysql:mysql "$DATADIR"
    mysqld --user=mysql --initialize-insecure
    touch /var/lib/mysql/.docker-initialized
  fi

  chown -R mysql:mysql "$DATADIR"

  echo "Starting temporary server"
  # Ensure runtime directory for socket exists and is owned by mysql
  mkdir -p /run/mysqld
  chown -R mysql:mysql /run/mysqld
  mysqld --user=mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  mysql=( mysql --protocol=socket -uroot -hlocalhost --socket=/run/mysqld/mysqld.sock )
  for i in {30..0}; do
    if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
      break
    fi
    echo 'MySQL init process in progress...'
    sleep 1
  done
  if [ "$i" = 0 ]; then
    echo >&2 'MySQL init process failed.'
    exit 1
  fi

  /usr/local/bin/init-db.sh "${mysql[@]}"

  echo "Shutting down temporary server"
  kill "$pid"
  wait "$pid"
fi

exec "$@"
