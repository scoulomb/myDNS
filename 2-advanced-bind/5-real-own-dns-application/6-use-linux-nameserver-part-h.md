# Revisit part g with CA

We will revisit:

- [section g, Ingress](6-use-linux-nameserver-part-g.md)

Where we will replace self-signed certificate by a certificate signed by let's encrypt certificate authority.

## Step 0: Prerequisite

This step is equivalent in [part g with self signed certificate : step 0](./6-use-linux-nameserver-part-g.md#step-0-prerequisite)


Start Minikube

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

you can see [DNS entries](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db) we will use in this section.

## Step 1: How to generate a self-signed certificate

### How to generate a self-signed certificate: Server validation (certbot server or own server)

This step is equivalent in [part g with self signed certificate : step 1](./6-use-linux-nameserver-part-g.md#step-1-how-to-generate-a-self-signed-certificate)

You need the DNS started as it will be used by let's encrypt. This is what we did in previous step.
We will follow proecdure described here with `--standalone`:
https://certbot.eff.org/lets-encrypt/ubuntufocal-other

````shell script
sudo snap install core; sudo snap refresh core
sudo apt-get remove certbot,
sudo snap install --classic certbot
sudo certbot certonly --standalone
````


You may have this issue 

````shell script
# sudo certbot certonly --standalone
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Please enter in your domain name(s) (comma and/or space separated)  (Enter 'c'
to cancel): coulombel.it
Requesting a certificate for coulombel.it
Performing the following challenges:
http-01 challenge for coulombel.it
Cleaning up challenges
Problem binding to port 80: Could not bind to IPv4 or IPv6.
````

Same with Python 

````shell script
root@sylvain-hp:/home/sylvain/certbot# python3 -m http.server 80
Traceback (most recent call last):
  File "/usr/lib/python3.8/runpy.py", line 194, in _run_module_as_main
    return _run_code(code, main_globals, None,
  File "/usr/lib/python3.8/runpy.py", line 87, in _run_code
    exec(code, run_globals)
  File "/usr/lib/python3.8/http/server.py", line 1294, in <module>
    test(
  File "/usr/lib/python3.8/http/server.py", line 1249, in test
    with ServerClass(addr, HandlerClass) as httpd:
  File "/usr/lib/python3.8/socketserver.py", line 452, in __init__
    self.server_bind()
  File "/usr/lib/python3.8/http/server.py", line 1292, in server_bind
    return super().server_bind()
  File "/usr/lib/python3.8/http/server.py", line 138, in server_bind
    socketserver.TCPServer.server_bind(self)
  File "/usr/lib/python3.8/socketserver.py", line 466, in server_bind
    self.socket.bind(self.server_address)
OSError: [Errno 98] Address already in use
````

The reason behind is that this port is in use by the ingress controller setup in previous [part g](6-use-linux-nameserver-part-g.md#step-5a--deploy-using-kubernetes-ingress-with-https)

````shell script
# netstat -pnltu | grep 80
tcp        0      0 192.168.1.32:2380       0.0.0.0:*               LISTEN      9081/etcd
tcp6       0      0 :::80                   :::*                    LISTEN      9687/docker-proxy
[...]
# docker container ls
CONTAINER ID        IMAGE                  COMMAND                  CREATED             STATUS              PORTS                                      NAMES
[...]
db7fa666959f        k8s.gcr.io/pause:3.2   "/pause"                 11 minutes ago      Up 11 minutes                                                  k8s_POD_coredns-66bff467f8-thvrl_kube-system_d1f3e6b9-3c27-4c50-9fec-72367a4d9bf0_1
9c24f634f6bc        k8s.gcr.io/pause:3.2   "/pause"                 11 minutes ago      Up 11 minutes       0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp   k8s_POD_ingress-nginx-controller-7bb4c67d67-v2bdw_kube-system_bbfa7ea9-314d-47ed-b551-805f13eecb5c_1
1e8d4e30924e        k8s.gcr.io/pause:3.2   "/pause"                 11 minutes ago      Up 11 minutes                                                  k8s_POD_coredns-66bff467f8-mgjjd_kube-system_e8e3e77e-bdc6-4db0-afd4-1ae840ccf424_1
[...]
````
This is explained here: https://stackoverflow.com/questions/58065039/problem-binding-to-port-80-could-not-bind-to-ipv4-or-ipv6-with-certbot

So we will disable it temporarily

````shell script
sudo minikube addons disable ingress
````

and retry

````shell script
sudo certbot certonly --standalone --domains home.coulombel.it
````

Output is 

````shell script
oot@sylvain-hp:/home/sylvain/certbot# sudo certbot certonly --standalone --domains home.coulombel.it
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator standalone, Installer None
Requesting a certificate for home.coulombel.it
Performing the following challenges:
http-01 challenge for home.coulombel.it
Waiting for verification...
Cleaning up challenges
Subscribe to the EFF mailing list (email: dev1@coulombel.it).

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/home.coulombel.it/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/home.coulombel.it/privkey.pem
   Your cert will expire on 2021-03-18. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le

````

To understand how it works, we have to be aware that `home.coulombel.it`, is pointing to our machine.
Because we have started a DNS server with following [DNS entries](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db).
Then let's encrypt deploys it own server for DNS validation (`--standalone`) on our machine, but a second method would be to use existing server in our machine (`--webserver`).

We certified sub-domain `home.coulombel.it`, and `coulombel.it` would not work as it points to github in current DNS setup.

We can see certificate and key are generated at: `/etc/letsencrypt/live/home.coulombel.it`

I prefer DNS validation.

### How to generate a self-signed certificate: TXT record validation

https://serverfault.com/questions/750902/how-to-use-lets-encrypt-dns-challenge-validation

For this we will perform DNS validation via a `TXT` record and validate `coulombel.it`.

````shell script
sudo certbot --manual --preferred-challenges dns certonly --domains *.coulombel.it
````

It will prompt the following 

````shell script
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.coulombel.it with the following value:

VkP-8UfyRRX9IbheXgCfwZxjf6U78JYxvT2e6ciR0O4

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
````

We will add to our [DNS entries](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db) the record:

````shell script
_acme-challenge IN TXT VkP-8UfyRRX9IbheXgCfwZxjf6U78JYxvT2e6ciR0O4
````

<!-- or _acme-challenge.coulombel.it. IN TXT -->

and restart the DNS in asecond window

```shell script
ssh sylvain@109.29.148.109
cd /path/to/repo
sudo chmod 777 ./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db

echo '_acme-challenge IN TXT VkP-8UfyRRX9IbheXgCfwZxjf6U78JYxvT2e6ciR0O4' >> ./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db

./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/6-use-linux-nameserver.sh
```



and test

````shell script
nslookup -type=TXT _acme-challenge.coulombel.it
````

Output is 

````shell script
$ nslookup -type=TXT _acme-challenge.coulombel.it
Server:         127.0.0.53
Address:        127.0.0.53#53

Non-authoritative answer:
_acme-challenge.coulombel.it    text = "VkP-8UfyRRX9IbheXgCfwZxjf6U78JYxvT2e6ciR0O4"

Authoritative answers can be found from:
````

So we can continue the process.

Full output is 

````shell script
$ sudo certbot --manual --preferred-challenges dns certonly --domains *.coulombel.it
[sudo] password for sylvain:
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator manual, Installer None
Requesting a certificate for *.coulombel.it
Performing the following challenges:
dns-01 challenge for coulombel.it

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.coulombel.it with the following value:

VkP-8UfyRRX9IbheXgCfwZxjf6U78JYxvT2e6ciR0O4

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
 - Congratulations! Your certificate and chain have been saved at:
   /etc/letsencrypt/live/coulombel.it-0001/fullchain.pem
   Your key file has been saved at:
   /etc/letsencrypt/live/coulombel.it-0001/privkey.pem
   Your cert will expire on 2021-03-18. To obtain a new or tweaked
   version of this certificate in the future, simply run certbot
   again. To non-interactively renew *all* of your certificates, run
   "certbot renew"
 - If you like Certbot, please consider supporting our work by:

   Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
   Donating to EFF:                    https://eff.org/donate-le

````



- The [*.key]() is located at `/etc/letsencrypt/live/coulombel.it/privkey.pem`  
- The [*.crt]() is located at `/etc/letsencrypt/live/coulombel.it/fullchain.pem`

It is strictly equivalent to 

```shell-script
openssl req -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out appa.prd.coulombel.it.crt -keyout appa.prd.coulombel.it.key
```

## Step 2: Configure the server to use HTTPS

This step is equivalent in [part g with self signed certificate : step 2](./6-use-linux-nameserver-part-g.md#step-2-configure-the-server-to-use-https).

Rather than using the module: `python3 -m http.server 8080`.
We have to write a server file and provide the certificate.

The server can be found in that [location](6-part-h-use-certificates-signed-by-ca/http_server.py).

````shell script
cd ./2-advanced-bind/5-real-own-dns-application/6-part-h-use-certificates-signed-by-ca
sudp python3 http_server.py
````

It is exposed on port 9443.
We can access via curl or browser on host machine via [localhost:9443](https://localhost:9443).

output is 

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ curl https://localhost:9443
curl: (60) SSL: no alternative certificate subject name matches target host name 'localhost'
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
sylvain@sylvain-hp:~/myDNS_hp$ curl --insecure https://localhost:9443
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
[...]
````

So the certificate is signed but we have a domain mismatch.
Compare with the equivalent in  [part g with self signed certificate : step 2](./6-use-linux-nameserver-part-g.md#step-2-configure-the-server-to-use-https) where it was self-signed error.

````shell script
sylvain@sylvain-hp:~$ curl https://localhost:9443
curl: (60) SSL certificate problem: self signed certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
````

To fix it we need to give the correct domain for which the certificate was generated: `*.coulombel.it`.
And given the  [DNS entry](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db) pointing to our machine where server is deployed:

````shell script
home             IN      CNAME     scoulomb.ddns.net.
````

and reverse NAT configured as follows

````shell script
Nom  Protocole Type Ports externe IP de destination Ports de destination
9443 TCP       Port 9443          192.168.1.32      9443
````

The command
````shell script
curl https://home.coulombel.it:9443 | head -n 5
````

will output

````shell script
$ curl https://home.coulombel.it:9443 | head -n 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   601  100   601    0     0  28619      0 --:--:-- --:--:-- --:--:-- 28619
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
````

which is working !
Opening it on a browser will enable to see it was certified by let's encrypt.

Note if we do, we will have a domain mismatch too if we do

<details><summary>expand</summary>
<p>


````shell script
curl https://scoulomb.ddns.net:9443 
curl https://109.29.148.109:9443
````

we fall into same error

````shell script
$ curl https://scoulomb.ddns.net:9443
curl: (60) SSL: no alternative certificate subject name matches target host name 'scoulomb.ddns.net'
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
$ curl https://109.29.148.109:9443
curl: (60) SSL: no alternative certificate subject name matches target host name '109.29.148.109'
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
````

In browser we can make a unsafe process.

Note the wildcard for which the certificate was generated `*.coulombel.it`.
If I had put `coulombel.it` in domain, `home.coulombel.it` would lead to do `certificate subject name matches target host name` error.
<!-- as coulombel.it does not point to home (ddns) -->

</p>
</details>

## This confirms, there are 3 possibilities
1. Certificate is self-signed, so we have to add it manually or use `--insecure`
1. Certificate is recognized by CA
1. Certificate is recognized by CA but does not match the domain, so we can proceed unsafely or use `--insecure`

## Step 3: Deploy using Kubernetes ingress with HTTPS

This step is equivalent in [part g with self signed certificate : step 5b](./6-use-linux-nameserver-part-g.md#step-5b--deploy-using-kubernetes-ingress-with-https-and-fix-case-2).

We will redeploy original application A and B from [part e](6-use-linux-nameserver-part-e.md).
This python application does not manage the certificate as it will be handled by Kubernetes unlike application exposed in [step 2 of this file](#step-2-configure-the-server-to-use-https).

````shell script
cd /path/to/repo
sudo su  # sudo -i would change the current dir; we use sudo as minikube run under sudo user

kubectl delete po a-server --force --grace-period=0
kubectl delete po b-server --force --grace-period=0
kubectl delete svc a-server
kubectl delete svc b-server

cd ./2-advanced-bind/5-real-own-dns-application/6-part-e-contenarized-http-server
sudo docker build . -f a.Dockerfile -t a-server
sudo docker build . -f b.Dockerfile -t b-server

kubectl run a-server --image=a-server --restart=Never --image-pull-policy=Never 
kubectl run b-server --image=b-server --restart=Never --image-pull-policy=Never 

# we can simplify as here nodeport is actually not necessary (so no specific port to mention)
kubectl expose po a-server --port 80 --target-port 8080
kubectl expose po b-server --port 80 --target-port 8080
````

We will configure a TLS secret with our let's encrypt certificate


````shell script
sudo kubectl delete secret tls-secret
sudo kubectl create secret tls tls-secret\
 --cert=/etc/letsencrypt/live/coulombel.it-0001/fullchain.pem\
 --key=/etc/letsencrypt/live/coulombel.it-0001/privkey.pem

sudo kubectl get secret/tls-secret -o yaml
````

So we will use [ingress v5](6-part-g-use-certificates/ingressv5.yaml) provided in [part g](6-use-linux-nameserver-part-g.md) and which confgures host based routing for
`appa.prd.coulombel.it` and `appb.prd.coulombel.it`.

````shell script
sudo minikube addons enable ingress
cd /path/t/repo
sudo kubectl delete ingress example-ingress
sudo kubectl apply -f 2-advanced-bind/5-real-own-dns-application/6-part-g-use-certificates/ingressv5.yaml
````

and we have [DNS entries](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db)

````shell script
appa.prd.coulombel.it
appb.prd.coulombel.it
````

pointing to the machine where ingress is running.

<!-- we could also use home.coulombel.it in ingress -->

We also had to configure NAT to route to the ingress

````shell script
80	TCP	Port	80	192.168.1.32	80   
443	TCP	Port	443	192.168.1.32	443
````

We can now test

````shell script
curl https://appa.prd.coulombel.it
````

But output is 

````shell script
root@sylvain-hp:~# curl https://appa.prd.coulombel.it
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
````

If we look at the certificate

````
openssl s_client -showcerts -connect appa.prd.coulombel.it:443
````

output is

````shell script
root@sylvain-hp:~# openssl s_client -showcerts -connect appa.prd.coulombel.it:443 | head -n 2
depth=0 O = Acme Co, CN = Kubernetes Ingress Controller Fake Certificate
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 O = Acme Co, CN = Kubernetes Ingress Controller Fake Certificate
verify error:num=21:unable to verify the first certificate
verify return:1
CONNECTED(00000003)
````

We can see we have `Kubernetes Ingress Controller Fake Certificate`.
As if we did no configure any certificate in the ingress. See [part g](6-use-linux-nameserver-part-g.md#step-5b--deploy-using-kubernetes-ingress-with-https-and-fix-case-2).

If we change to the self-singed certificate used in [part g](6-use-linux-nameserver-part-g.md#step-5b--deploy-using-kubernetes-ingress-with-https-and-fix-case-2)

````shell script
cd /path/to/repo
sudo kubectl delete secret tls-secret
sudo kubectl create secret tls tls-secret\
 --cert=./2-advanced-bind/5-real-own-dns-application/6-part-g-use-certificates/appa.prd.coulombel.it.crt\
 --key=./2-advanced-bind/5-real-own-dns-application/6-part-g-use-certificates/appa.prd.coulombel.it.key
````

and perform

````shell script
curl https://appa.prd.coulombel.it
openssl s_client -showcerts -connect appa.prd.coulombel.it:443 | head -n 2
````

output is 

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ curl https://appa.prd.coulombel.it
curl: (60) SSL certificate problem: self signed certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
sylvain@sylvain-hp:~/myDNS_hp$ openssl s_client -showcerts -connect appa.prd.coulombel.it:443 | head -n 2
depth=0 C = FR, ST = PACA, L = Antibes, O = Home, CN = appa.prd.coulombel.it., emailAddress = dev@coulombel.it
verify error:num=18:self signed certificate
verify return:1
depth=0 C = FR, ST = PACA, L = Antibes, O = Home, CN = appa.prd.coulombel.it., emailAddress = dev@coulombel.it
verify return:1
CONNECTED(00000003)
---
````

We do not have the fake but self-signed certificate.
So ingress is ok, secret is ok but we have an issue with our let's encrypt certificate.

Moreover quoting: https://stackoverflow.com/questions/59356528/kubernetes-tls-secret-certificate-expiration

> In general, "Kubernetes ingress Controller Fake certificate" indicates problems on the certificates itself or in your setup.

I found that Kubernetes does not support wildcard on DNS name :(.

Therefore I created a dedicated certificate for `appa.prd.coulombel.it`.
Following same procedure as [How to generate a self-signed certificate: TXT record validation](#how-to-generate-a-self-signed-certificate-txt-record-validation).

````shell script
sudo certbot --manual --preferred-challenges dns certonly --domains appa.prd.coulombel.it
echo '_acme-challenge.appa.prd IN TXT bzPzkjgdki9k0tLaoaqOYpo9GvFXQHivuCPd4IviOtA' >> ./2-advanced-bind/5-real-own-dns-application/6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db
````

Then we updated the secret with this new certificate

````shell script
sudo kubectl delete secret tls-secret
sudo kubectl create secret tls tls-secret\
 --cert=/etc/letsencrypt/live/appa.prd.coulombel.it/fullchain.pem\
 --key=/etc/letsencrypt/live/appa.prd.coulombel.it/privkey.pem
````


and 

````shell script
curl https://appa.prd.coulombel.it
openssl s_client -showcerts -connect appa.prd.coulombel.it:443 | head -n 2
````

will finally work successfully

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ curl https://appa.prd.coulombel.it
Hello app A
sylvain@sylvain-hp:~/myDNS_hp$ openssl s_client -showcerts -connect appa.prd.coulombel.it:443 | head -n 2
depth=2 O = Digital Signature Trust Co., CN = DST Root CA X3
verify return:1
depth=1 C = US, O = Let's Encrypt, CN = R3
verify return:1
depth=0 CN = appa.prd.coulombel.it
verify return:1
CONNECTED(00000003)
---
````

In chrome you can see we have a safe https !


### Extended test

````shell script
clear
curl http://appa.prd.coulombel.it:80
curl -L http://appa.prd.coulombel.it:80
curl https://appa.prd.coulombel.it:443
curl http://appb.prd.coulombel.it:80
curl https://appb.prd.coulombel.it:443
curl -k https://appb.prd.coulombel.it:443
````


output is 

````shell script
sylvain@sylvain-hp:~$ curl http://appa.prd.coulombel.it:80
<html>
<head><title>308 Permanent Redirect</title></head>
<body>
<center><h1>308 Permanent Redirect</h1></center>
<hr><center>nginx/1.17.10</center>
</body>
</html>
sylvain@sylvain-hp:~$ curl -L http://appa.prd.coulombel.it:80
Hello app A
sylvain@sylvain-hp:~$ curl https://appa.prd.coulombel.it:443
Hello app A
sylvain@sylvain-hp:~$ curl http://appb.prd.coulombel.it:80
<html>
<head><title>308 Permanent Redirect</title></head>
<body>
<center><h1>308 Permanent Redirect</h1></center>
<hr><center>nginx/1.17.10</center>
</body>
</html>
sylvain@sylvain-hp:~$ curl https://appb.prd.coulombel.it:443
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
sylvain@sylvain-hp:~$ curl -k https://appb.prd.coulombel.it:443
Hello app B
sylvain@sylvain-hp:~$
````

Conclusion is that ingress implements redirection from `http` to `https`.
Connection to `appb` in `https` is diabled and we need to use insecure.

And if we add to ingressv5 a rule to `scoulomb.ddns.net`.
We have [ingressv6](./6-part-h-use-certificates-signed-by-ca/ingressv6.yaml).

````shell script
sudo kubectl apply -f 2-advanced-bind/5-real-own-dns-application/6-part-h-use-certificates-signed-by-ca/ingressv6.yaml
````

Output would be

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ sudo kubectl apply -f 2-advanced-bind/5-real-own-dns-application/6-part-h-use-certificates-signed-by-ca/ingressv6.yaml^C
sylvain@sylvain-hp:~/myDNS_hp$ curl https://scoulomb.ddns.net
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
sylvain@sylvain-hp:~/myDNS_hp$ curl -k https://scoulomb.ddns.net
Hello app A
sylvain@sylvain-hp:~/myDNS_hp$ openssl s_client -showcerts -connect scoulomb.ddns.net:443 | head -n 2
depth=0 O = Acme Co, CN = Kubernetes Ingress Controller Fake Certificate
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 O = Acme Co, CN = Kubernetes Ingress Controller Fake Certificate
verify error:num=21:unable to verify the first certificate
verify return:1
CONNECTED(00000003)
````

As name mismatch Kubernetes return the fake certificate.

<!-- 
In real OpenShift we saw that default certificate can be a default one matching the wildcard rather than `Kubernetes Ingress Controller Fake Certificate`,
If the route is matching the wildcard ok,
If the route is matching a specific DNS, certificate name will mismatch, see section ["This confirms, there are 3 possibilities"](#this-confirms-there-are-3-possibilities)
We will have to define specific DNS at route level to override it as we did here in the example
Here we also have a wildcard: [DNS entry](./6-docker-bind-dns-use-linux-nameserver-rather-route53/fwd.coulombel.it.db)
-->

## Parallel 

- Google could run, custom domain mapping generates certificate for you:
See real life example https://github.com/scoulomb/attestation-covid19-saison2-auto#mapping-custom-domain-in-cloud-run and the doc:
https://cloud.google.com/run/docs/mapping-custom-domains?hl=fr.

So the custom domain configures the ingress but also generates a certificate.
They even plug to DNS provider API like Gand.

- Here had mention we could attach certif to Ingress: https://github.com/scoulomb/aws-sa-exo/blob/master/sa-question-c.adoc

- In AWS when we manage certificate it is attached to the ELB.
See https://github.com/scoulomb/aws-sa-exo/blob/master/templates/AWS-SA-CloudFormation-v20190724_partb-step5-from-step4-us.yaml#L195

````shell script
LoadBalancerListenerHTTPS:
  Type: 'AWS::ElasticLoadBalancingV2::Listener'
  Properties:
    Certificates:
      - CertificateArn: arn:aws:acm:us-east-1:818241204187:certificate/f4e9b5a7-b98d-4d30-9518-eddca1b6ce55
    DefaultActions:
    - Type: forward
      TargetGroupArn: !Ref LoadBalancerTargetGroup
    LoadBalancerArn: !Ref SAelb
    Port: 443
    Protocol: HTTPS
    SslPolicy: ELBSecurityPolicy-2016-08
````


Which is not present in initial file.

- Github page also manages certificates

- In kubernetes 
We had seen that each service account has a secret: https://github.com/scoulomb/myk8s/blob/master/Volumes/secret-doc-deep-dive.md#side-note-on-service-account
We had seen that when using a service account, a token is attached to it and mounted as volume in the pod. See section on service account.
This enable the pod to use kube API.

If we do 

````shell script
sylvain@sylvain-hp:~/myDNS_hp$ sudo kubectl get secret default-token-7gjpd -o yaml
apiVersion: v1
data:
  ca.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUM1ekNDQWMrZ0F3SUJBZ0lCQVRBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwdGFXNXAKYTNWaVpVTkJNQjRYRFRJd01EVXlNREl5TURjMU1Wb1hEVE13TURVeE9USXlNRGMxTVZvd0ZURVRNQkVHQTFVRQpBeE1LYldsdWFXdDFZbVZEUVRDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBSzBICldibFJIb2xUYWIvUy9BY0Rzb25FS0twcTJSOCs0Y1NWcm8vamNXNFliSVV3VlRJTGpjbkhHYWpteGZWME51VDIKYlQ2TWM4aGdjVVBod1Z3ekVWNDFMMHQ0K1hRWVhuQkowR0kya1JKdkZhU240ckJ6VDVSbFJIVW9rU0RZWlppVwprd1pNY0dqSkU2WXhhV28yNUJjazVxZTFWbWRoR0QyQndKa04rekdncXlUUGZnZy8wQVJ5Q0FvK05YR0VJVGdzCnNtWnpCUHdmcjhNWnRFcFRHdDdaMzRpODd6REpmbUtVUG9idUpralZ3UXVpVC9FTDhxWFlwTnAva0pvUjJwbVIKbHVrOUhMUTBFSVh0ZGpZT2JFKy9mRSt6VWFtQ2R5QlNoM1ZYVWJ6TEZwTmZHdmNTcmFOUGw3a1JiN1BrSnZmSAp4LzVCcWNKZlpwazQ1T2VXTmo4Q0F3RUFBYU5DTUVBd0RnWURWUjBQQVFIL0JBUURBZ0trTUIwR0ExVWRKUVFXCk1CUUdDQ3NHQVFVRkJ3TUNCZ2dyQmdFRkJRY0RBVEFQQmdOVkhSTUJBZjhFQlRBREFRSC9NQTBHQ1NxR1NJYjMKRFFFQkN3VUFBNElCQVFBSHRUbnphNnB3U29tZmRNQXZYd1Y3UjVtYWExbjUycytiQ01yS1lmbGtGYisrLy9NQQpuSFVsSGJZUnRzQTg0WTlvUmhNYlFOb3hqK2d0bFI1cEwrYkk2SDJTWUxoWHY3VWVFdWZiSzhyUm5tR0hpSG5VCmcwaEhPZ1ZvTUwvZ01peXVrTmFac2ZVbjFPdjl0UGEvR1ZvNmE1NWZqVW1aUTV1b0hBcXUwUEhSMDFjdUs1Nm8KVWgxOTV3dkNVVDh2Q0l6UzE1TW1QRnEzbU9JQ1lHNWh2WGxYbXZRdHdNSllIT1hoNWJsdHVWOWNZQWhvQjdaawpJUERnZ1h6QTU1SVZsMHFiNGJybDUxZGxWQTE5dEIwcXhZZ2JTeEx3Z1hBUit6WXJRNURtTkhtQTVEeGdDdDc2CjlHSnFWRktoOCtSak45VnlYbmdEMUtpbExnUkRXNGpkMFZYTwotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
  namespace: ZGVmYXVsdA==
  token: ZXlKaGJHY2lPaUpTVXpJMU5pSXNJbXRwWkNJNklubHNSWFprZVRSMVgyWktiMEZyYkRCcGJIQnlWMjlZWTNCelJrbzFjVFpDZEZGQmNHOVJjVUp4TkdzaWZRLmV5SnBjM01pT2lKcmRXSmxjbTVsZEdWekwzTmxjblpwWTJWaFkyTnZkVzUwSWl3aWEzVmlaWEp1WlhSbGN5NXBieTl6WlhKMmFXTmxZV05qYjNWdWRDOXVZVzFsYzNCaFkyVWlPaUprWldaaGRXeDBJaXdpYTNWaVpYSnVaWFJsY3k1cGJ5OXpaWEoyYVdObFlXTmpiM1Z1ZEM5elpXTnlaWFF1Ym1GdFpTSTZJbVJsWm1GMWJIUXRkRzlyWlc0dE4yZHFjR1FpTENKcmRXSmxjbTVsZEdWekxtbHZMM05sY25acFkyVmhZMk52ZFc1MEwzTmxjblpwWTJVdFlXTmpiM1Z1ZEM1dVlXMWxJam9pWkdWbVlYVnNkQ0lzSW10MVltVnlibVYwWlhNdWFXOHZjMlZ5ZG1salpXRmpZMjkxYm5RdmMyVnlkbWxqWlMxaFkyTnZkVzUwTG5WcFpDSTZJalkzWWpNM01tUm1MVE5oTmprdE5HWTJNeTFoT0RrNExUUXlZVGxrWVdFNVpHVXhNU0lzSW5OMVlpSTZJbk41YzNSbGJUcHpaWEoyYVdObFlXTmpiM1Z1ZERwa1pXWmhkV3gwT21SbFptRjFiSFFpZlEudElxdTJBOGhhbFF0UkpEMHVTc1ZEcFh6WldORjh4TUNrbFZrMjlxOFE2b3d1a2FWUEpGUHBJc1VoVkhxRU9JVll5T24xelNUOC1kWHZYSC10YWdxUkU5V2Z6Q1J6N0lTTUNJTzhQZTctSDVSNUxfMnd4dTBQRkVJX202V1hCNTNoNmhYeXdzenY2VkFtRk5HeFl6NkR1X1VhaGZxVlNXemNtMjRQNzM3eGxfc281MDNIeV9GTGR5MUdtWGc1M0c0RTJQT0NJQWNCc3NydGdvdE05eW42ODloazdDVE43SVpSYTZVTVpKai1PWEVRQ0xhamNYYjRmM0E0RUNuZE54TTZTUTBFN3ctSGUzU1BtQlNPdFAxamt1V19QUExTTzlnbkRXOFhDVGt5cU5KR3JRTGl0X1RvcVZMaHNTdGtkelBnbDFCWEtaVWtqYTdUTkZIMEQ2eV93
kind: Secret
````

We can see we have a certificate.

TODO: 

See tls explained to myself:https://github.com/scoulomb/misc-notes/tree/master/tls

