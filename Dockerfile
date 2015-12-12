FROM jjungo/lamp
#MAINTAINER l3iggs <l3iggs@live.com>
MAINTAINER jjungo <j.jungo@gmail.com>
# Report issues here: https://github.com/l3iggs/docker-owncloud/issues
# Say thanks by adding a star or a comment here: https://registry.hub.docker.com/u/l3iggs/owncloud/

# set environmnt variable defaults
ENV REGENERATE_SSL_CERT false
ENV START_APACHE true
ENV START_MYSQL true
ENV MAX_UPLOAD_SIZE 30G
ENV TARGET_SUBDIR owncloud
ENV OC_VERSION '*'

# remove info.php
RUN rm /srv/http/info.php

# upldate package list
RUN pacman -Sy \

    # to to run cron as HTTP
    && pacman -S --noconfirm --needed sudo \
    # to mount SAMBA shares:
    && pacman -S --noconfirm --needed smbclient \
    # for video file previews
    && pacman -S --noconfirm --needed ffmpeg \
    # for document previews
    && pacman -S --noconfirm --needed libreoffice-fresh \
    # Install owncloud
    && pacman -Sw --noconfirm --needed owncloud \
    && pacman -U --noconfirm --needed /var/cache/pacman/pkg/owncloud-${OC_VERSION}-any.pkg.tar.xz

# add our custom config.php
ADD configs/oc-config.php /usr/share/webapps/owncloud/config/config.php
# fixup the permissions (because appairently the package maintainer can't get it right)
ADD fixPerms.sh /root/fixPerms.sh
RUN chmod +x /root/fixPerms.sh
RUN /root/fixPerms.sh

# Install owncloud addons
RUN pacman -S --noconfirm --needed owncloud-app-bookmarks \
    && pacman -S --noconfirm --needed owncloud-app-calendar \
    && pacman -S --noconfirm --needed owncloud-app-contacts \
    && pacman -S --noconfirm --needed owncloud-app-documents \
    && pacman -S --noconfirm --needed owncloud-app-gallery

# disable Apache's dav in favor of the dav built into OC
RUN sed -i 's,^DAVLockDB /home/httpd/DAV/DAVLock,#&,g' /etc/httpd/conf/httpd.conf \
    && sed -i 's,^LoadModule dav_module modules/mod_dav.so,#&,g' /etc/httpd/conf/httpd.conf \
    && sed -i 's,^LoadModule dav_fs_module modules/mod_dav_fs.so,#&,g' /etc/httpd/conf/httpd.conf \
    && sed -i 's,^LoadModule dav_lock_module modules/mod_dav_lock.so,#&,g' /etc/httpd/conf/httpd.conf \

    # enable large file uploads
    && sed -i "s,php_value upload_max_filesize 513M,php_value upload_max_filesize ${MAX_UPLOAD_SIZE},g" /usr/share/webapps/owncloud/.htaccess \
    && sed -i "s,php_value post_max_size 513M,php_value post_max_size ${MAX_UPLOAD_SIZE},g" /usr/share/webapps/owncloud/.htaccess \
    && sed -i 's,<IfModule mod_php5.c>,<IfModule mod_php5.c>\nphp_value output_buffering Off,g' /usr/share/webapps/owncloud/.htaccess \
    # set up PHP for owncloud
    # fixes issue with config not editable and occ errors (Issue #44)
    && sed -i 's/open_basedir = \/srv\/http\/:\/home\/:\/tmp\/:\/usr\/share\/pear\/:\/usr\/share\/webapps\//open_basedir = \/srv\/http\/:\/home\/:\/tmp\/:\/usr\/share\/pear\/:\/usr\/share\/webapps\/:\/etc\/webapps\//g' /etc/php/php.ini \
    # needed for cron / occ (Issue #42)
    && sed -i 's/;extension=posix.so/extension=posix.so/g' /etc/php/php.ini \

    # setup Apache for owncloud
    && cp /etc/webapps/owncloud/apache.example.conf /etc/httpd/conf/extra/owncloud.conf \
    && sed -i '/<VirtualHost/,/<\/VirtualHost>/d' /etc/httpd/conf/extra/owncloud.conf \
    && sed -i 's,Alias /owncloud /usr/share/webapps/owncloud/,Alias /${TARGET_SUBDIR} /usr/share/webapps/owncloud/,g' /etc/httpd/conf/extra/owncloud.conf \
    && sed -i '/<Directory \/usr\/share\/webapps\/owncloud\/>/a Header always add Strict-Transport-Security "max-age=15768000; includeSubDomains; preload"' /etc/httpd/conf/extra/owncloud.conf \
    && sed -i 's,php_admin_value open_basedir "[^"]*,&:/dev/urandom,g' /etc/httpd/conf/extra/owncloud.conf \
    && sed -i '$a Include conf/extra/owncloud.conf' /etc/httpd/conf/httpd.conf \
    && chown -R http:http /usr/share/webapps/owncloud/

# expose some important directories as volumes
#VOLUME ["/usr/share/webapps/owncloud/data"]
#VOLUME ["/etc/webapps/owncloud/config"]
#VOLUME ["/usr/share/webapps/owncloud/apps"]

# place your ssl cert files in here. name them server.key and server.crt
#VOLUME ["/https"]

# Enable cron (Issue #42)
RUN pacman -S --noconfirm --needed cronie
RUN systemctl enable cronie.service
ADD configs/cron.conf /etc/oc-cron.conf
RUN crontab /etc/oc-cron.conf
RUN systemctl start cronie.service; exit 0 # force success due to issue with cronie start https://goo.gl/DcGGb

# start servers
CMD ["/root/startServers.sh"]
