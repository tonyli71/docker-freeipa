# Clone from the Fedora 21 image
FROM fedora:21

MAINTAINER Jan Pazdziora

# Install FreeIPA server
RUN mkdir -p /run/lock ; yum install -y freeipa-server bind bind-dyndb-ldap perl && yum clean all

ADD dbus.service /etc/systemd/system/dbus.service
RUN ln -sf dbus.service /etc/systemd/system/messagebus.service
ADD httpd.service /etc/systemd/system/httpd.service

ADD systemctl /usr/bin/systemctl
ADD systemctl-socket-daemon /usr/bin/systemctl-socket-daemon

ADD ipa-server-configure-first /usr/sbin/ipa-server-configure-first

RUN chmod -v +x /usr/bin/systemctl /usr/bin/systemctl-socket-daemon /usr/sbin/ipa-server-configure-first

RUN groupadd -g 389 dirsrv ; useradd -u 389 -g 389 -c 'DS System User' -d '/var/lib/dirsrv' --no-create-home -s '/sbin/nologin' dirsrv
RUN groupadd -g 17 pkiuser ; useradd -u 17 -g 17 -c 'CA System User' -d '/var/lib' --no-create-home -s '/sbin/nologin' pkiuser

ADD volume-data-list /etc/volume-data-list
ADD volume-data-mv-list /etc/volume-data-mv-list
RUN cd / ; mkdir /data-template ; cat /etc/volume-data-list | while read i ; do if [ -e $i ] ; then tar cf - .$i | ( cd /data-template && tar xf - ) ; fi ; mkdir -p $( dirname $i ) ; rm -rf $i ; ln -sf /data${i%/} ${i%/} ; done
RUN mv /data-template/etc/dirsrv/schema /usr/share/dirsrv/schema && ln -s /usr/share/dirsrv/schema /data-template/etc/dirsrv/schema
RUN echo 0.5 > /etc/volume-version
RUN uuidgen > /data-template/build-id

EXPOSE 53/udp 53 80 443 389 636 88 464 88/udp 464/udp 123/udp 7389 9443 9444 9445

VOLUME /data

ENTRYPOINT /usr/sbin/ipa-server-configure-first
