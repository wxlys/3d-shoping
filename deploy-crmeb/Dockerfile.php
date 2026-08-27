FROM docker.m.daocloud.io/library/php:7.4-fpm

RUN sed -i 's|http://deb.debian.org|http://mirrors.aliyun.com|g' /etc/apt/sources.list \
    && sed -i 's|http://security.debian.org|http://mirrors.aliyun.com/debian-security|g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql bcmath gd zip exif \
    && pecl install redis-5.3.7 \
    && docker-php-ext-enable redis \
    && printf 'upload_max_filesize = 100M\npost_max_size = 110M\nmax_execution_time = 300\nmemory_limit = 256M\n' > /usr/local/etc/php/conf.d/zz-crmeb.ini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html
EXPOSE 9000
