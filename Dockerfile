FROM ubuntu-debootstrap:14.04
MAINTAINER Christian Lück <christian@lueck.tv>

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y \
  nginx supervisor php5-fpm php5-cli \
  php5-pgsql php5-mysql php5-sqlite php5-mssql \
  wget

# add adminer as the only nginx site
ADD adminer.nginx.conf /etc/nginx/sites-available/adminer
RUN ln -s /etc/nginx/sites-available/adminer /etc/nginx/sites-enabled/adminer
RUN rm /etc/nginx/sites-enabled/default

# install adminer and default theme
RUN mkdir /var/www
RUN wget http://www.adminer.org/latest.php -O /var/www/index.php
RUN wget https://raw.github.com/vrana/adminer/master/designs/hever/adminer.css -O /var/www/adminer.css
WORKDIR /var/www
RUN chown www-data:www-data -R /var/www

# tune PHP settings for uploading large dumps
RUN echo "upload_max_filesize = 2000M" >> /etc/php5/upload_large_dumps.ini \
 && echo "post_max_size = 2000M"       >> /etc/php5/upload_large_dumps.ini \
 && echo "memory_limit = -1"           >> /etc/php5/upload_large_dumps.ini \
 && echo "max_execution_time = 0"      >> /etc/php5/upload_large_dumps.ini \
 && ln -s ../../upload_large_dumps.ini /etc/php5/fpm/conf.d \
 && ln -s ../../upload_large_dumps.ini /etc/php5/cli/conf.d


 COPY doctrine-migrations.phar /usr/local/share/doctrine-migrations.phar

 #copy executable file to /usr/local/bin
 RUN cp /usr/local/share/doctrine-migrations.phar /usr/local/bin/doctrine-migrations

 RUN chmod 655 /usr/local/bin/doctrine-migrations

 # install Composer
 RUN php -r "readfile('https://getcomposer.org/installer');" > composer-setup.php
 RUN php -r "if (hash('SHA384', file_get_contents('composer-setup.php')) === 'fd26ce67e3b237fffd5e5544b45b0d92c41a4afe3e3f778e942e43ce6be197b9cdc7c251dcde6e2a52297ea269370680') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); }"
 RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
 RUN php -r "unlink('composer-setup.php');"

 VOLUME /app

 WORKDIR /app

# expose only nginx HTTP port
EXPOSE 80

ADD freetds.conf /etc/freetds/freetds.conf

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD supervisord -c /etc/supervisor/conf.d/supervisord.conf
