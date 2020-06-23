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

COPY view1-fwd.mylabserver.com.db /etc/bind/view1-fwd.mylabserver.com.db
RUN named-checkzone fwd.mylabserver.com /etc/bind/view1-fwd.mylabserver.com.db
COPY view2-fwd.mylabserver.com.db /etc/bind/view2-fwd.mylabserver.com.db
RUN named-checkzone fwd.mylabserver.com /etc/bind/view2-fwd.mylabserver.com.db
COPY view3-fwd.mylabserver.com.db /etc/bind/view3-fwd.mylabserver.com.db
RUN named-checkzone fwd.mylabserver.com /etc/bind/view3-fwd.mylabserver.com.db

RUN chmod 760 /etc/bind/view1-fwd.mylabserver.com.db
RUN chgrp bind /etc/bind/view1-fwd.mylabserver.com.db
RUN chmod 760 /etc/bind/view2-fwd.mylabserver.com.db
RUN chgrp bind /etc/bind/view2-fwd.mylabserver.com.db
RUN chmod 760 /etc/bind/view3-fwd.mylabserver.com.db
RUN chgrp bind /etc/bind/view3-fwd.mylabserver.com.db

EXPOSE 53