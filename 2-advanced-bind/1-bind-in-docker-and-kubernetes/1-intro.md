# Bind in docker and kubernetes 

## Intro

From [networking_2ndEd](https://docstore.mik.ua/orelly/networking_2ndEd/dns/ch10_06.htm):

> BIND 9 introduced views, another mechanism that's very useful in firewalled environments. Views allow you to present one name server configuration to one community of hosts and a different configuration to another community. 

It means that DNS response will depends on source IP (the subnet it belongs) of the requestor.

To simulate hosts with different subnets, my idea is to use Kubernetes to show the view concept.
We will also leverage it to explain forwarding and delegation concept since it is more convenient than to deploy several VMs!


See [next section](2-understand-source-ip-in-k8s.md).