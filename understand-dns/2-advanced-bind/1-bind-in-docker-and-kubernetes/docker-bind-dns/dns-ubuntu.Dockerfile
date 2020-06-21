FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
# https://www.tecmint.com/install-dig-and-nslookup-in-linux/
RUN apt install dnsutils -y # for nslookup

RUN cat /etc/bind/named.conf
COPY named.conf /etc/bind/named.conf
RUN named-checkconf

COPY fwd.mylabserver.com.db /etc/bind/fwd.mylabserver.com.db
RUN named-checkzone fwd.mylabserver.com /etc/bind/fwd.mylabserver.com.db

RUN chmod 760 /etc/bind/fwd.mylabserver.com.db
RUN chgrp bind /etc/bind/fwd.mylabserver.com.db

EXPOSE 53