FROM ioft/armhf-debian:latest

# File Author / Maintainer
MAINTAINER Bernhard Esperester <bernhard@esperester.de>

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

# configure mysql-server
RUN debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''" \
	&& debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ''" \
	&& debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ''" \
	&& debconf-set-selections <<< "mysql-community-server mysql-community-server/remove-test-db select false"

# install mysql-server
RUN apt-get update && apt-get -y install mysql-server && apt-get clean && rm -rf /var/lib/apt/lists/*

# fix folder permissions
RUN rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
	&& chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
	&& chmod 777 /var/run/mysqld

# comment out a few problematic configuration values
# don't reverse lookup hostnames, they are usually another container
RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/mysql.conf.d/mysqld.cnf \
	&& echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
