FROM debian
MAINTAINER Paul Smith code@uvwxy.de

# dependency setup
RUN apt-get update
RUN apt-get install -y \
		check-mk-livestatus \
		build-essential \
		libapache2-mod-python \
		nagios3 \
		python \
		sudo
RUN apt-get clean

# fix check_mk looking in wrong places
RUN cd /etc/ && ln -s nagios3 nagios
RUN cd /usr/sbin/ && ln -s nagios3 nagios
RUN cd /var/lib/ && rmdir nagios && ln -s nagios3 nagios
RUN cd /var/log/ && ln -s /var/lib/nagios3 nagios

# add default admin account
RUN cd /etc/nagios/ && htpasswd -bc htpasswd.users admin admin

# add sudo rules required for check_mk
RUN echo "Defaults:www-data !requiretty" >> /etc/sudoers
RUN echo "www-data ALL = (root) NOPASSWD: /usr/bin/check_mk --automation *" >> /etc/sudoers

# register livestatus
RUN echo "broker_module=/usr/lib/check_mk/livestatus.o /var/lib/nagios/rw/live" >> /etc/nagios3/nagios.cfg 
RUN echo "event_broker_options=-1" >> /etc/nagios3/nagios.cfg 


# checkmk installation
ADD check_mk/ /setup/
RUN cd /setup/ && bash setup.sh --yes

# fix check_mk config (again)
RUN cd /usr/share/check_mk/web/htdocs/ && sed -e 's/\/var\/log\/nagios\/rw\/live/\/var\/lib\/nagios3\/rw\/live/g' -i defaults.py 

RUN cd /var/lib/check_mk/wato && mkdir auth && chgrp nagios auth && chmod 770 auth/
RUN usermod -a -G nagios www-data


ADD run.sh /