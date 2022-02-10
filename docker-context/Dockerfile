#############################
# Markus Hilsenbeck
# svnserver with apache and http:// protocol
# Feb 2022

# use LTS 20.04, because svnadmin need php 7.4
FROM ubuntu:20.04

LABEL Maintainer="Markus Hilsenbeck" \
      E-Mail="markus.dev@hilsi.de" \
      GitHub="https://github.com/MarkusH1975/"


# Add Tini init process running as pid 1
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "-w", "-v", "--"]
      

# Install svn, apache, php
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -y apt-utils && \
    apt-get install --no-install-recommends -y \
    vim nano sudo wget curl unzip lsof \
    locales \
    cron \
    apache2 apache2-utils libapache2-mod-svn libapache2-mod-php \
    php7.4 php7.4-json php7.4-xml \
    pwauth \
    subversion \
    && apt-get clean && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*


# generate some locales
RUN locale-gen \
    de_DE.UTF-8 \
    en_GB.UTF-8 \
    en_US.UTF-8

# volume: create directories
RUN mkdir -p /volume/svnadmin && \
    mkdir -p /volume/svnconf && \
    mkdir -p /volume/svnrepo

# svnadmin: download
# svnadmin is already old and was desinged for php5.3, but seems to run good with php7.4
RUN wget --no-check-certificate https://github.com/mfreiholz/iF.SVNAdmin/archive/stable-1.6.2.zip &&\
	unzip stable-1.6.2.zip -d /opt &&\
	rm stable-1.6.2.zip &&\
	mv /opt/iF.SVNAdmin-stable-1.6.2 /opt/svnadmin

# svnadmin: link from apache dir
RUN ln -svf /opt/svnadmin /var/www/html/svnadmin && \
	chmod -R 777 /opt/svnadmin/data
	
# svnadmin: Fixing https://github.com/mfreiholz/iF.SVNAdmin/issues/118
ADD svnadmin/classes/util/global.func.php /opt/svnadmin/classes/util/global.func.php

# svnadmin: Adding template data for svnadmin with predefined pathes
ADD svnadmin/data/config.tpl.ini /opt/svnadmin/data/config.tpl.ini
# svnadmin: move svnadmin/data/ to /volume/ and create symlink
RUN mv -fv /opt/svnadmin/data /volume/svnadmin/ && \
    ln -sfv /volume/svnadmin/data /opt/svnadmin/data


# apache: add auth/passwd files
ADD apache/dav_svn.authz /volume/svnconf/dav_svn.authz
ADD apache/dav_svn.passwd /volume/svnconf/dav_svn.passwd


# apache: add config file
ADD apache/apache2_svn.conf /etc/apache2/sites-enabled/000-default.conf

# apache: set up the apache environment variables
ENV APACHE_RUN_USER www-data \
    APACHE_RUN_GROUP www-data \
 	APACHE_RUN_DIR /var/run/apache2 \
    APACHE_PID_FILE /var/run/apache2.pid \
    APACHE_LOG_DIR /var/log/apache2 \
    APACHE_LOG_LEVEL=warn \
    APACHE_LOCK_DIR /var/lock/apache2
    
# apache: set some servername to suppress warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf 

# apache: enable apache2 modules 
RUN a2enmod dav dav_fs dav_svn auth_digest

# volume: set permissions
RUN chown -Rv www-data /volume/svnconf && \
    chown -Rv www-data /volume/svnrepo && \
    chmod -Rfv 777 /volume/svnadmin && \
    chmod -Rfv 777 /volume/svnconf && \
    chmod -Rfv 777 /volume/svnrepo

# volume: copy everything to the template folder for automatic generation
RUN cp -fvra /volume /volume.template

#Ports to be exposed by container
EXPOSE 80

# Environment variables: select services to be started
ENV ENABLE_APACHE=true \
    ENABLE_CRON=false

# To force docker build to invalidate cache from now on, to be sure entrypoint.sh is updated
# docker build --build-arg CACHE_DATE=$(date +%Y-%m-%d:%H:%M:%S) -t svnserver.apache .
ARG CACHE_DATE
RUN echo "\n* Docker image build time: $CACHE_DATE"

# add startup script
COPY entrypoint.sh /

# CMD will be executed by tini 
CMD ["/bin/bash", "/entrypoint.sh"]
