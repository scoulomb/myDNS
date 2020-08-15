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

COPY fwd.it.db /etc/bind/fwd.it.db
RUN named-checkzone fwd.it.db /etc/bind/fwd.it.db

COPY fwd.gandi.net.db /etc/bind/fwd.gandi.net.db
RUN named-checkzone fwd.gandi.net.db /etc/bind/fwd.gandi.net.db

RUN chmod 760 /etc/bind/fwd.it.db
RUN chgrp bind /etc/bind/fwd.it.db
RUN chmod 760 /etc/bind/fwd.gandi.net.db
RUN chgrp bind /etc/bind/fwd.gandi.net.db

EXPOSE 53

ENTRYPOINT ["systemctl",  "start",  "named", ";", "systemctl", "enable",  "named", ";", "sleep", "3600"]
