# Use linux nameserver via NAT

We could have used own DNS nameserver deployed on Ubuntu rather than Route53 in section:

- [modify tld nsrecord](./2-modify-tld-ns-record.md)
- [delegate subzone](./5-delegate-subzone.md)

For this we need to configure a reverse NAT.

1. We will start by showing how to configure a reverse NAT in [part A](6-use-linux-nameserver-part-a.md) to access application:
    - a simple HTTP application (Python Server, Jupyter) 
    - or SSH
2. In a second step we will apply same principle to the DNS: [part B](6-use-linux-nameserver-part-b.md)
and show how this DNS can be used to reference application deployed in our network itself

We show an example where we apply concept of part A and B with VLC here:
https://github.com/scoulomb/music-streamer#cname-to-ddns-advanced

3. We used router DNS (Internet Box) override for traffic swicth between public and private IP.
This approach is working for Gandi and own DNS, we wills show how to use DNS view when we have our own nameserver.
 
In this example I am using SFR box.


### Notes 

We could use Jupyter notebook for this demo.
But as we also show here how to setup it, to not confuse (inception) I decided to not use it.

However if needed to do a demo with remote access to my laptop it remains possible:
- use Jupyter bash
- use SSH (also avoids to switch laptop. Pull that repo for script via SSH)
This we will be configured in this tutorial.

<!-- if not blocked, corpo worked and stop working osef -->
