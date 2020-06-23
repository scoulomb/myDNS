# Azure views

How to implement view in Azure?

From:
https://docs.microsoft.com/en-us/azure/dns/private-dns-overview#:~:text=Split%2Dhorizon%20DNS%20support.,use%20inside%20your%20virtual%20network.

This what they call `Split-horizon DNS support.`
> Split-horizon DNS support. With Azure DNS, you can create zones with the same name that resolve to different answers from within a virtual network and from the public internet. A typical scenario for split-horizon DNS is to provide a dedicated version of a service for use inside your virtual network.

It is same as view: https://en.wikipedia.org/wiki/Split-horizon_DNS 

From:
- https://docs.microsoft.com/en-us/azure/dns/private-dns-getstarted-portal
- https://docs.microsoft.com/en-us/azure/dns/private-dns-scenarios

Quoting the [doc](https://docs.microsoft.com/en-us/azure/dns/private-dns-scenarios#scenario-split-horizon-functionality):
> In this scenario, you have a use case where you want to realize different DNS resolution behavior depending on where the client sits (inside of Azure or out on the internet), for the same DNS zone.

> For example, you may have a private and public version of your application that has different functionality or behavior, but you want to use the same domain name for both versions. 

It is exactly same scenario as [bind here](../../2-advanced-bind/2-bind-views/bind-views.md)
This is why in [2](./2-Azure-authoritative-DNS.md#private-dns) there was a link between a private zone and a network.

> This scenario can be realized with Azure DNS by creating a Public DNS zone as well as a Private Zone, with the same name.

So view implementation in Azure is performed by create a publicZone and a privateZone with the same name (zone being something like `mylabserver.com`) 



