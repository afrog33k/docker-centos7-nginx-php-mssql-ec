FROM centos:centos7.6.1810

# Project ENV
ENV LARAVEL=true
ENV PROJECT_NAME=projectName
ENV INIT_DB=yes
ENV MACHINE=master
ENV APP_ENV=local
# Git Clone Project
# ENV GITPROJECT
ENV USE_GIT=false
ENV GIT_PROJECT=github.com/defsrisars/laravel-test.git
ENV BRANCH_NAME=develop
# SESSION SETTING
ENV SESSION_DRIVER=file

ENV container=docker

# install nginx
RUN yum -y install epel-release && \
    yum -y install nginx && \
    systemctl enable nginx
ADD conf/nginx/nginx.conf /etc/nginx/nginx.conf
RUN mkdir -p /etc/nginx/sites-available/ && \
    mkdir -p /etc/nginx/sites-enabled/ && \
    mkdir -p /etc/nginx/ssl/ && \
    mkdir -p /var/www/html/
ADD conf/nginx/nginx-site.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
ADD conf/nginx/errors /var/www/errors

# install php72
RUN yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
    yum -y install yum-utils && \
    yum-config-manager --enable remi-php72 && \
    yum -y update && \
    yum -y install php72 php-devel php-pear php72-php-devel php72-php-pear php72-php-fpm php72-php-gd php72-php-json php72-php-mbstring php72-php-mysqlnd php72-php-xml php72-php-xmlrpc php72-php-opcache php72-php-pecl-zip && \
    yum -y install centos-release-scl && \
    yum -y install devtoolset-7 && \
    systemctl enable php72-php-fpm.service
ADD conf/php-fpm-config.conf /etc/opt/remi/php72/php-fpm.d/www.conf

# install require package and composer
RUN yum -y install unzip zip wget gcc git && \
    yum -y install centos-release-scl && \
    yum -y install devtoolset-7-gcc* && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Composer.phar Installer verified'; } else { echo 'Composer.phar Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && \
    php composer-setup.php --install-dir=/usr/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"  && \
    composer global require hirak/prestissimo

# install mssql
RUN echo "source scl_source enable devtoolset-7" >> /etc/bashrc && \
    source /etc/bashrc && \
    cd / && \
    curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/mssqlrelease.repo && \
    ACCEPT_EULA=Y yum -y install msodbcsql mssql-tools unixODBC-devel && \
    wget http://pecl.php.net/get/pdo_sqlsrv-5.6.1.tgz && \
    tar -zxvf pdo_sqlsrv-5.6.1.tgz && \
    cd pdo_sqlsrv-5.6.1 && \
    /usr/bin/phpize && \
    ./configure --with-php-config=/usr/bin/php-config && \
    make && make install && \
    cd .. && \
    rm -rf pdo_sqlsrv-5.6.1 && \
    rm -f pdo_sqlsrv-5.6.1.tgz && \
    rm -f /usr/bin/php && \
    ln -s /usr/bin/php72 /usr/bin/php && \
    pecl install sqlsrv && \
    pecl install pdo_sqlsrv && \
    echo "extension=pdo_sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini && \
    echo "extension=sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/20-sqlsrv.ini

# install supervisor
RUN yum -y install supervisor && \
    systemctl enable supervisord.service && \
    mkdir -p /etc/supervisord.d
ADD conf/supervisord/supervisord.conf /etc/supervisord.conf
ADD conf/supervisord/laravel.ini /etc/supervisord.d/laravel.ini
RUN sed -i "s|/var/www/html|$PROJECT_NAME|g" /etc/supervisord.d/laravel.ini

# install crontab
RUN yum -y install crontabs && \
    systemctl enable crond.service
ADD conf/crontab /etc/crontab

RUN yum clean all

ADD start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 80

WORKDIR "/"

CMD ["/usr/sbin/init"]
