FROM php:8.0-apache

RUN apt update && apt install -y apt-utils

# Ativar https
RUN a2enmod ssl

# Permissão para o usuário do apache acessar a pasta de arquivos do protocolo
# se necessário, adcionar o usuário da máquina atual no grupo www-data
RUN chown -R www-data:www-data /var/www/html \
    && a2enmod rewrite && service apache2 restart

# Instalação de libs
RUN apt-get update \
    && apt-get install -y \
    nano \
    wget \
    libzip-dev \
    zlib1g-dev \
    freetds-bin \
    freetds-dev \
    freetds-common \
    libct4 \
    libsybdb5 \
    tdsodbc \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libldap2-dev \
    zlib1g-dev \
    libc-client-dev \
    libxml2-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/lib/x86_64-linux-gnu/libsybdb.a /usr/lib/ 

# Instalação outras extensões do PHP
RUN docker-php-ext-install mysqli pdo_mysql zip bcmath dba dom pdo pdo_dblib soap sysvmsg sysvsem sysvshm calendar gd xml

# Instalação do driver SQLServer
# RUN DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    gnupg \
    gnupg2 \
    curl \
    unzip \
    libpng-dev \
    unixodbc-dev \
    libc-client-dev libkrb5-dev

RUN docker-php-ext-install pdo pdo_mysql pdo_pgsql zip xml \
    && pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && a2enmod rewrite

# Instalar a extensão IMAP
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install -j$(nproc) imap

# COPY php.ini /usr/local/etc/php/

RUN echo extension=sqlsrv.so > /usr/local/etc/php/conf.d/docker-php-ext-sqlsrv.ini

RUN echo extension=pdo_sqlsrv.so > /usr/local/etc/php/conf.d/docker-php-ext-pdo-sqlsrv.ini

# SQL Server
RUN wget https://packages.microsoft.com/keys/microsoft.asc && \
    apt-key add microsoft.asc && \
    curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
    unixodbc \
    unixodbc-dev \
    msodbcsql18 \
    mssql-tools18

# UnixODBC
RUN wget ftp://ftp.unixodbc.org/pub/unixODBC/unixODBC-2.3.11.tar.gz && \
    tar -xzf unixODBC-2.3.11.tar.gz && \
    cd unixODBC-2.3.11 && \
    ./configure --enable-ltdl-install --prefix=/usr/local/unixODBC && \
    make && \
    make install

# Instalação do APCu cache
RUN pecl install apcu && echo extension=apcu.so > /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini

# # Install Postgre PDO
# RUN apt-get install -y libpq-dev \
#     && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
#     && docker-php-ext-install pdo pdo_pgsql pgsql

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
# RUN php -r "if (hash_file('sha384', 'composer-setup.php') === '756890a4488ce9024fc62c56153228907f1545c228516cbf63f885e036d37e9a59d27d63f46af1d4d07ee0f76181c7d3') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN mv composer.phar /usr/local/bin/composer

ENV TZ=America/Fortaleza
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone