FROM debian:jessie
MAINTAINER crdil <cardiel@gmx.com>

ENV NGINX_VER 1.9.12

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential dnsutils imagemagick libpcre3 libpcre3-dev libpcrecpp0 libssl-dev php5-curl php5-gd php5-fpm php5-imagick php5-mcrypt php5-memcache php5-memcached php5-mysql ssmtp supervisor zlib1g-dev wget whois

RUN (wget http://nginx.org/download/nginx-${NGINX_VER}.tar.gz -O /tmp/nginx-${NGINX_VER}.tar.gz && \
	cd /tmp && \
	tar xvf /tmp/nginx-${NGINX_VER}.tar.gz && \
	cd /tmp/nginx-${NGINX_VER} \
	&& ./configure --sbin-path=/usr/local/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --http-log-path=/var/log/nginx/access.log --with-http_dav_module --http-client-body-temp-path=/var/lib/nginx/body --with-http_ssl_module --with-http_realip_module --http-proxy-temp-path=/var/lib/nginx/proxy --with-http_stub_status_module --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --with-http_auth_request_module --user=www-data --group=www-data && \
	cd /tmp/nginx-${NGINX_VER} && \
	make && \
	make install && \
	rm /etc/nginx/*.default && \
	rm -rf /tmp/nginx-${NGINX_VER} /tmp/nginx-${NGINX_VER}.tar.gz)
RUN mkdir -p /var/lib/nginx /etc/nginx/sites-enabled /etc/nginx/sites-available /var/www

ADD nginx.conf /etc/nginx/nginx.conf
ADD php.conf /etc/nginx/php.conf
ADD default.conf /etc/nginx/sites-available/default
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default &&\
  sed -i -e "s/;daemonize = yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf &&\
  sed -i -e "s/post_max_size = 8M/post_max_size = 16M/g" /etc/php5/fpm/php.ini &&\
  sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 50M/g" /etc/php5/fpm/php.ini &&\
  sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini &&\
  sed -i -e "s/error_log\s*=\s*\/var\/log\/php5-fpm.log/error_log = \/var\/log\/nginx\/php5-fpm.log/g" /etc/php5/fpm/php-fpm.conf &&\
  sed -i -e "s/pm = dynamic/pm = ondemand/g" /etc/php5/fpm/pool.d/www.conf

RUN rm -rf /var/lib/apt/lists/* &&\
    rm -rf /usr/share/man/?? &&\
    rm -rf /usr/share/man/??_*

VOLUME ["/var/www", "/var/log/nginx"]
EXPOSE 80

CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]
