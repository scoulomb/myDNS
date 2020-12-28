# Note on coulombel.it on github page

## Reminder

The repo can be found here:
https://github.com/scoulomb/dev_resume

And from readme instruction it is published here:
https://github.com/scoulomb/scoulomb.github.io

We could have made a CI/CD like here: https://github.com/scoulomb/github-page-helm-deployer
But the template we use has some issue with Docker.

We can use it via scoulmb.github.io as explained here: https://github.com/scoulomb/github-page-helm-deployer
But can define a custom DNS as explained here: https://github.com/scoulomb/github-page-helm-deployer/blob/master/appendix-github-page-and-dns.md
Then we have a CNAME file for name mapping.

Output is this DNS configuration: https://github.com/scoulomb/dns-config

##  We can also replace Gandi DNS server
 
Gandi config is given here: https://github.com/scoulomb/dns-config/blob/600fd4bc7aa1df272f9f5f68b6e279ff5f8208dc/it/fwd.coulombel.it.db#L28

We can replace Gandi by our DNS server:


````shell script
ssh sylvain@109.29.148.109
cd /path/to/repo
sudo minikube start --vm-driver=none
sudo su
````

And start own DNS nameserver from [part b](6-use-linux-nameserver-part-b.md).
We use following [script](./6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh). 

```shell script
./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
```

Where you can see [DNS entries](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db) 

````shell script
;; GITHUB page
@	             IN      A  	 185.199.108.153
@	             IN      A		 185.199.109.153
@	             IN      A       185.199.110.153
@	             IN      A		 185.199.111.153
````

Open browser to https://coulombel.it/. (checked 19 dec 2020)
We can see it is working and that certificate is let's encrypt 
<!-- use device were not cert mim -->

## Link 
Note the link with [part f analysis](6-use-linux-nameserver-part-f.md#analysis).

And [part h parallel](6-use-linux-nameserver-part-h.md#parallel).
As GCR we have apex (A) and non apex (CNAME). 

GCR, k8s ingress, and Openshift routes (we create 2 routes) can map several domain and github only one: 
https://stackoverflow.com/questions/16454088/can-github-pages-cname-file-contain-more-than-one-domain

## CNAME github file

Updating CNAME file: https://github.com/scoulomb/scoulomb.github.io/blob/master/CNAME
will impact the configuration here: https://github.com/scoulomb/scoulomb.github.io/settings

We could actually push it directly (as README welcome page).

Behind it generates CNAME mapping but also the certificate.
<!-- proof coulombel.site started certif process -->

Unlike GCR we did DNS validation, **here we understand it is more similar to certbot with server validation technique.**
This was described in [part h](6-use-linux-nameserver-part-h.md#how-to-generate-a-self-signed-certificate-server-validation-certbot-server-or-own-server).

<!-- all above is ok -->

## Use Gandi live DNS

For domain `coulombel.it`, we use our own nameserver.
To set back to Gandi live DNS.
Go to Gandi, select domain, choose domain, nameserver tab and edit.
And configure records: https://github.com/scoulomb/dns-config/blob/master/it/fwd.coulombel.it.db

(be aware of [negative TTL](../6-cache/negative-ttl.md) if record were not present,)

<!-- can see dns corp is != -->


