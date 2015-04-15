FROM netivism/docker-wheezy-mariadb 
MAINTAINER Jimmy Huang <jimmy@netivism.com.tw>

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
    apache2 \
    libapache2-mod-php5 \
    php5-common \
    php5-curl \
    php5-gd \
    php5-mcrypt \
    php5-mysql \
    php5-curl \
    php5-cli \
    curl \
    vim \
    git-core \
    wget && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  git clone https://github.com/NETivism/docker-sh.git /home/docker

### Apache
# remove default enabled site
RUN \
  rm -f /etc/apache2/sites-enabled/000-default && \
  a2enmod php5 && a2enmod rewrite && \ 
  rm -f /etc/apache2/conf.d/security.conf && \
  rm -f /etc/apache2/conf.d/security && \
  ln -s /home/docker/apache/netivism.conf /etc/apache2/conf.d/ && \
  ln -s /home/docker/php/default55.ini /etc/php5/apache2/conf.d/

ADD sources/apache/security.conf /etc/apache2/conf.d/security.conf

ENV \
  APACHE_RUN_USER=www-data \
  APACHE_RUN_GROUP=www-data \
  APACHE_LOG_DIR=/var/log/apache2 \
  APACHE_LOCK_DIR=/var/lock/apache2 \
  APACHE_PID_FILE=/var/run/apache2.pid

### END
WORKDIR /home/docker
