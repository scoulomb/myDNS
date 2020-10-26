# Use linux nameserver via NAT

We could have used own DNS nameserver deployed on Ubuntu rather than Route53 in section:

- [modify tld nsrecord](./2-modify-tld-ns-record.md)
- [delegate subzone](./5-delegate-subzone.md)

For this we need to configure a reverse NAT.

1. We will start by showing how to configure a reverse NAT in [part A](6-use-linux-nameserver-part-a.md) to access application:
    - a simple HTTP application (Python Server, Jupyter) 
    - or SSH
2. In a second step we will apply same principle to the DNS: [part B](6-use-linux-nameserver-part-b.md)
3. Finally we will show how this DNS can be used to reference application deployed in our network itself
4. How we can use DNS for traffic switch between public IP when outside the LAN and private IP when inside the LAN
    1. Using router DNS (Internet Box) override
    2. Using DNS view
4. Same as `3. and 4.`can obviously be achieved with Gandi to target application except `4.ii` dns view

In this example I am using SFR box.


### Notes 

We could use Jupyter notebook for this demo.
But as we also show here how to setup it, to not confuse (inception) I decided to not use it.

However if needed to do a demo with remote access to my laptop it remains possible:
- use Jupyter bash
- use SSH (also avoids to switch laptop. Pull that repo for script via SSH)
This we will be configured in this tutorial.

<!-- if not blocked, corpo worked and stop working osef -->
