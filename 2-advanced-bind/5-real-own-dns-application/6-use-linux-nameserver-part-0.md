# Use linux nameserver via NAT

We could have used own DNS nameserver deployed on Ubuntu rather than route53 in section:

- [modify tld nsrecord](./2-modify-tld-ns-record.md)
- [delegate subzone](./5-delegate-subzone.md)


For this we need to configure  a reverse NAT.

- We will start by showing how to configure a reverse NAT for a simple server (python server or Jupyter): [part A](6-use-linux-nameserver-part-a.md).
- In a second step we will apply same principle to the DNS: [part B](6-use-linux-nameserver-part-b.md)

In this example I am using SFR box.
