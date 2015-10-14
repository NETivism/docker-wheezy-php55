FROM netivism/docker-wheezy-mariadb 
MAINTAINER Jimmy Huang <jimmy@netivism.com.tw>

ENV \
  APACHE_RUN_USER=www-data \
  APACHE_RUN_GROUP=www-data \
  APACHE_LOG_DIR=/var/log/apache2 \
  APACHE_LOCK_DIR=/var/lock/apache2 \
  APACHE_PID_FILE=/var/run/apache2.pid \
  COMPOSER_HOME=/root/.composer \
  PATH=/root/.composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

WORKDIR /etc/apt/sources.list.d
RUN echo "deb http://packages.dotdeb.org wheezy all" > dotdeb.list \
    && echo "deb-src http://packages.dotdeb.org wheezy all" >> dotdeb.list \
    && echo "deb http://packages.dotdeb.org wheezy-php55 all" >> dotdeb.list \
    && echo "deb-src http://packages.dotdeb.org wheezy-php55 all" >> dotdeb.list \
    && apt-get update && apt-get install -y wget && wget http://www.dotdeb.org/dotdeb.gpg \
    && apt-key add dotdeb.gpg && \
    rm -f dotdeb.gpg

WORKDIR /
RUN \
  apt-get update && \
  apt-get install -y \
    rsyslog \
    apache2 \
    libapache2-mod-php5 \
    php5-common \
    php5-curl \
    php5-gd \
    php5-mcrypt \
    php5-memcached \
    php5-mysql \
    php5-curl \
    php5-cli \
    curl \
    vim \
    git-core && \
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  composer global require drush/drush:7.0.0 && \
  git clone https://github.com/NETivism/docker-sh.git /home/docker

### Apache
# remove default enabled site
RUN \
  rm -f /etc/apache2/sites-enabled/000-default && \
  a2enmod php5 && a2enmod rewrite && \ 
  rm -f /etc/apache2/conf.d/security.conf && \
  rm -f /etc/apache2/conf.d/security && \
  ln -s /home/docker/apache/netivism.conf /etc/apache2/conf.d/ && \
  ln -s /home/docker/php/default55.ini /etc/php5/apache2/conf.d/ && \
  ln -s /home/docker/php/default55_cli.ini /etc/php5/cli/conf.d/ && \
  mkdir -p /var/www/html/log/supervisor && \
  sed -i 's/KeepAlive[ ]*On*/KeepAlive Off/g' /etc/apache2/apache2.conf && \
  sed -i 's/StartServers[ ]*[0-9]*/StartServers 1/g' /etc/apache2/apache2.conf && \
  sed -i 's/MinSpareServers[ ]*[0-9]*/MinSpareServers 1/g' /etc/apache2/apache2.conf && \
  sed -i 's/MaxSpareServers[ ]*[0-9]*/MaxSpareServers 2/g' /etc/apache2/apache2.conf && \
  sed -i 's/MaxClients[ ]*[0-9]*/MaxClients 10/g' /etc/apache2/apache2.conf

RUN apt-get install -y supervisor

# wkhtmltopdf
RUN \
  apt-get install -y fonts-droid fontconfig libfontconfig1 libfreetype6 libpng12-0 libjpeg8 libssl1.0.0 libx11-6 libxext6 libxrender1 xfonts-75dpi xfonts-base && \
  cd /tmp && \
  wget -nv http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-wheezy-amd64.deb -O wkhtmltox.deb && \
  dpkg -i wkhtmltox.deb && \
  rm -f wkhtmltox.deb && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

ADD container/apache/security.conf /etc/apache2/conf.d/security.conf
ADD container/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

### END
WORKDIR /var/www/html
CMD ["/usr/bin/supervisord"]
