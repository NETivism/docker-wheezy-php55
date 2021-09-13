#!/bin/bash
set -eo pipefail

function doUpgrade() {
  mysqld --skip-networking --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --user=mysql --log-error=/var/www/html/log/mysql.log &
  PID=$!
  while ! pgrep -u mysql mysqld > /dev/null; do sleep 3; done
  sleep 10
  mysqldump --add-drop-table -uroot -p$INIT_PASSWD mysql > /var/lib/mysql/before-upgrade_mysql.sql
  mysql_upgrade -uroot -p$INIT_PASSWD
  while pgrep -u root mysql_upgrade; do sleep 3; done
  if ! kill -s TERM $PID || ! wait $PID; then
    exit 1
  fi
}

# Get config

if [ ! -d "/var/run/mysqld" ]; then
  mkdir -p /var/run/mysqld
  chown mysql:mysql /var/run/mysqld
  echo "" > /var/www/html/log/mysql.log
  chown mysql:mysql /var/www/html/log/mysql.log
fi
if [ ! -d "/var/lib/mysql/mysql" ]; then
  mkdir -p /var/lib/mysql

  echo 'Initializing database'
  mysql_install_db --datadir="/var/lib/mysql"
  echo 'Database initialized'

  "mysqld" --skip-networking &
  pid="$!"

  mysql=( mysql --protocol=socket -uroot )

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

  if ! kill -s TERM "$pid" || ! wait "$pid"; then
    echo >&2 'MySQL init process failed.'
    exit 1
  fi

  echo
  echo 'MySQL init process done. Ready for start up.'
  echo
else
  NeedToUpgrade=""

  if [ ! -f /var/lib/mysql/mysql_upgrade_info ]; then
    NeedToUpgrade="true"
  fi

  if [ -f /var/lib/mysql/mysql_upgrade_info ]; then
    Version=$(cat /var/lib/mysql/mysql_upgrade_info | awk -F "-" '{print $1}')
    isCurrentVersion=$(dpkg -l | grep 'mariadb-common' | { grep "$Version" || true; })
    if [ -z "$isCurrentVersion" ]; then
      NeedToUpgrade="true"
    fi
  fi

  if [ -n "$NeedToUpgrade" ]; then
    doUpgrade
  fi
fi

exec env LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4 "mysqld" --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mysql/plugin --user=mysql --log-error=/var/www/html/log/mysql.log
