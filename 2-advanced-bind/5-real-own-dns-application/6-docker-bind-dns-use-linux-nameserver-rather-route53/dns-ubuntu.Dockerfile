FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
# https://www.tecmint.com/install-dig-and-nslookup-in-linux/
RUN apt install dnsutils -y # for nslookup

COPY named.conf /etc/bind/named.conf
RUN named-checkconf
RUN cat /etc/bind/named.conf

COPY fwd.coulombel.it.db /etc/bind/fwd.coulombel.it.db
RUN named-checkzone fwd.coulombel.it /etc/bind/fwd.coulombel.it.db

RUN chmod 760 /etc/bind/fwd.coulombel.it.db
RUN chgrp bind /etc/bind/fwd.coulombel.it.db

# Default expose is TCP: https://docs.docker.com/engine/reference/builder/#expose
# Note EXPOSE instruction does not actually publish the port. It functions as a type of documentation between the person who builds the image and the person who runs the container
EXPOSE 53/udp

COPY start.sh start.sh
RUN chmod u+x start.sh

ENTRYPOINT ["./start.sh"]
