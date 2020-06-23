# DNS

My Deep dive into DNS

## TOC
 
### Basic Linux BIND 

BIND is Berkely Internet Name Domain.

This from LXA - LPIC-2 Topic 207.

#### Part 1

- [DNS cache](1-basic-bind-lxa/p1-1-dns-cache.md)
- [RNDC key](1-basic-bind-lxa/p1-2-rndc-key.md)

#### Part 2

- [Configure forward zone](1-basic-bind-lxa/p2-1-configure-forward-zone.md)
    - [Summary](1-basic-bind-lxa/p2-1-summary-configure-forward-zone.md)
    - [Personal questions](1-basic-bind-lxa/p2-1-xx-questions.md)
    - [Note on recursvive and authoritative](1-basic-bind-lxa/p2-1-zz-note-on-recursive-and-authoritative-dns.md)
- [Configure reverse zone](1-basic-bind-lxa/p2-2-configure-reverse-zone.md)
    - [Summary](1-basic-bind-lxa/with-archlinux-p2-2-summary-configure-reverse-zone.md)
    - [Personal questions](1-basic-bind-lxa/p2-2-xx-questions.md)
- [DNS querying](1-basic-bind-lxa/p2-3-DNS-querying.md)
    - [Summary](1-basic-bind-lxa/p2-3-summary-DNS-querying.md)
    - [Personal questions](1-basic-bind-lxa/p2-3-xx-questions.md)
- With ArchLinux local setup
    - [With ArchLinux - Configure forward zone](1-basic-bind-lxa/with-archlinux-p2-1-summary-configure-forward-zone.md)
    - [With ArchLinux - Configure reverse zone](1-basic-bind-lxa/with-archlinux-p2-2-summary-configure-reverse-zone.md)  
#### Part 3

- [Make a chroot jail](1-basic-bind-lxa/p3-1-chroot-jail.md)


### Advanced bind

- Bind in docker and k8s (pre-requisite for views)
    - [Intro](2-advanced-bind-bind-in-docker-and-kubernetes/1-intro.md)
    - [Understand source IP in k8s](2-advanced-bind-bind-in-docker-and-kubernetes/2-understand-source-ip-in-k8s.md)
    - [Deploy named in a pod](2-advanced-bind-bind-in-docker-and-kubernetes/3-deploy-named-in-a-pod.md)  
- [Bind view](2-advanced-bind-bind-views/bind-views.md)
- [Configure forward DNS](2-advanced-bind-bind-forwarders/dns-forwarding.md)

### DNS solutions providers

#### Infoblox

- [Infoblox comparison](3-DNS-solution-providers/1-Infoblox/2-Infoblox-parallel-question-with-bind.md)
- [Infoblox namespace](3-DNS-solution-providers/1-Infoblox/3-Infoblox-namespace.md)

#### Azure

- [Azure authoritative vs recursive DNS](3-DNS-solution-providers/2-Azure-DNS/1-Azure-authoritative-vs-recursive-dns.md)
- [Azure authoritative DNS](3-DNS-solution-providers/2-Azure-DNS/2-Azure-authoritative-DNS.md)
- [Azure DNS REST API](3-DNS-solution-providers/2-Azure-DNS/3-Azure-rest-api.md)
- [Azure views](3-DNS-solution-providers/2-Azure-DNS/4-Azure-views.md)
- [Azure API details](3-DNS-solution-providers/2-Azure-DNS/5-azure-api-details.md)

### Google

- [Google DNS API](3-DNS-solution-providers/3-Google-DNS/1-Google-DNS.md)

#### Analysis

- [Comparison table: bind9, Azure and Infoblox DNS AP ](4-Analysis/1-comparison-table.md)
- [Compare APIs](4-Analysis/2-compare-apis.md)
- [Toward a k8s APIs](4-Analysis/3-towards-a-k8s-like-api.md)
