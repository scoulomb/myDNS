# Use linux nameserver via NAT

We could have used own DNS nameserver deployed on Ubuntu rather than Route53 in section:

- [modify tld nsrecord](./2-modify-tld-ns-record.md)
- [delegate subzone](./5-delegate-subzone.md)

For this we need to configure a reverse NAT.

- We will start by showing how to configure a reverse NAT in [part A](6-use-linux-nameserver-part-a.md) to access application:
    - a simple HTTP application (Python Server, Jupyter) 
    - or SSH
- In a second step we will apply same principle to the DNS: [part B](6-use-linux-nameserver-part-b.md)
and show how this DNS can be used to reference application deployed in our network itself

We show an example where we apply concept of part A and B with VLC here:
https://github.com/scoulomb/music-streamer

Note python http server can also play music file.

<!--
(concluded 27/10/2020, can check new browse feature optionally)
comment in part 0, A, B judged -> ok
-->

Then we have various extensions

- [part C](6-use-linux-nameserver-part-c.md): complementary comments
- [part D](6-use-linux-nameserver-part-d.md): Notes on Docker
- [part E](6-use-linux-nameserver-part-e.md): Note on Docker container, Docker compose, Kubernetes and OpenShift 
- [part F](6-use-linux-nameserver-part-f.md): Use Kubernetes ingress rule for application deployed behind the DNS
- [part G](6-use-linux-nameserver-part-g.md): Revisit part e and f with self-signed certificates  
- [part H](6-use-linux-nameserver-part-h.md): Revisit part g with CA
- [part I](6-use-linux-nameserver-part-i.md): Note on coulombel.it on github page
- [part J](6-use-linux-nameserver-part-j.md): NAT, IPv4 and DNS, and move to IPv6
- [part K](6-use-linux-nameserver-part-j.md): Others

In this example I am using SFR box.


### Notes 

We could use Jupyter notebook for this demo.
But as we also show here how to setup it, to not confuse (inception) I decided to not use it.

However if needed to do a demo with remote access to my laptop it remains possible:
- use Jupyter bash
- use SSH (also avoids to switch laptop. Pull that repo for script via SSH)
This we will be configured in this tutorial.
