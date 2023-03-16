FROM ghcr.io/netivism/docker-debian-base:buster
MAINTAINER Jimmy Huang <jimmy@netivism.com.tw>

ENV \
  COMPOSER_HOME=/root/.composer \
  PATH=/root/.composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#mariadb
WORKDIR /etc/apt/sources.list.d
RUN \
    apt-get update && \
    apt-get install -y apt-transport-https wget gnupg && \
    echo "deb https://packages.sury.org/php/ buster main" > phpsury.list && \
    echo "deb-src https://packages.sury.org/php/ buster main" >> phpsury.list && \
    wget https://packages.sury.org/php/apt.gpg  && apt-key add apt.gpg && rm -f apt.gpg && \
    apt-get update && \
    apt-get install -y wget mariadb-server mariadb-backup gcc make autoconf libc-dev pkg-config google-perftools qpdf

WORKDIR /
RUN \
  apt-get update && \
  apt-get install -y \
    rsyslog \
    php5.6 \
    php5.6-curl \
    php5.6-imap \
    php5.6-gd \
    php5.6-mysql \
    php5.6-mbstring \
    php5.6-xml \
    php5.6-memcached \
    php5.6-mcrypt \
    php5.6-cli \
    php5.6-fpm \
    php5.6-zip \
    php5.6-bz2 \
    php5.6-ssh2 \
    php5.6-yaml \
    curl \
    vim \
    unzip \
    git-core

RUN \
  mkdir -p /root/.composer && \
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  composer global require drush/drush:8.3.0 && \
  cd /root/.composer && \
  composer clearcache

RUN apt-get install -y supervisor procps

# wkhtmltopdf
WORKDIR /tmp
RUN \
  apt-get install -y fonts-droid-fallback fontconfig ca-certificates fontconfig libc6 libfreetype6 libjpeg62-turbo libpng16-16 libssl1.1 libstdc++6 libx11-6 libxcb1 libxext6 libxrender1 xfonts-75dpi xfonts-base zlib1g && \
  wget -nv https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.buster_amd64.deb -O wkhtmltox.deb && \
  dpkg -i wkhtmltox.deb && \
  rm -f wkhtmltox.deb

RUN \
  apt-get remove -y gcc make autoconf libc-dev pkg-config && \
  apt-get autoremove -y && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

### PHP FPM Config
# remove default enabled site
RUN \
  mkdir -p /var/www/html/log/supervisor && \
  git clone https://github.com/NETivism/docker-sh.git /home/docker && \
  cp -f /home/docker/php/default56.ini /etc/php/5.6/docker_setup.ini && \
  ln -s /etc/php/5.6/docker_setup.ini /etc/php/5.6/fpm/conf.d/ && \
  cp -f /home/docker/php/default56_cli.ini /etc/php/5.6/cli/conf.d/ && \
  cp -f /home/docker/php/default_opcache_blacklist /etc/php/5.6/opcache_blacklist && \
  sed -i 's/^listen = .*/listen = 80/g' /etc/php/5.6/fpm/pool.d/www.conf && \
  sed -i 's/^pm = .*/pm = ondemand/g' /etc/php/5.6/fpm/pool.d/www.conf && \
  sed -i 's/;daemonize = .*/daemonize = no/g' /etc/php/5.6/fpm/php-fpm.conf && \
  sed -i 's/^pm\.max_children = .*/pm.max_children = 8/g' /etc/php/5.6/fpm/pool.d/www.conf && \
  sed -i 's/^;pm\.process_idle_timeout = .*/pm.process_idle_timeout = 15s/g' /etc/php/5.6/fpm/pool.d/www.conf && \
  sed -i 's/^;pm\.max_requests = .*/pm.max_requests = 50/g' /etc/php/5.6/fpm/pool.d/www.conf && \
  sed -i 's/^;request_terminate_timeout = .*/request_terminate_timeout = 7200/g' /etc/php/5.6/fpm/pool.d/www.conf

COPY container/mysql/mysql-init.sh /usr/local/bin/mysql-init.sh
COPY container/rsyslogd/rsyslog.conf /etc/rsyslog.conf
COPY container/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN \
  mkdir -p /run/php && chmod 777 /run/php

RUN \
  echo "source /usr/share/vim/vim81/defaults.vim" > /etc/vim/vimrc.local && \
  echo "let skip_defaults_vim = 1" >> /etc/vim/vimrc.local && \
  echo "if has('mouse')" >> /etc/vim/vimrc.local && \
  echo "  set mouse=" >> /etc/vim/vimrc.local && \
  echo "endif" >> /etc/vim/vimrc.local

### END
WORKDIR /var/www/html
ENV TERM=xterm
CMD ["/usr/bin/supervisord"]
