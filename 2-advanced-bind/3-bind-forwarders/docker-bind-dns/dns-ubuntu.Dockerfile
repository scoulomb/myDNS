FROM ubuntu
RUN apt-get update
RUN apt-get install bind9 -y
RUN apt-get install bind9-utils -y
RUN apt-get install systemctl -y
# https://www.tecmint.com/install-dig-and-nslookup-in-linux/
RUN apt install dnsutils -y # for nslookup

RUN cat /etc/bind/named.conf
COPY named.conf /etc/bind/named.conf
COPY named.conf.options /etc/bind/named.conf.options
RUN named-checkconf

EXPOSE 53