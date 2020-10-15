# Use linux nameserver via NAT - part A

## Configure a reverse NAT simple example

We will take as an example how to access on a basic HTTP server outside local network

### Deploy the server locally

https://docs.python.org/3/library/http.server.html

````shell script
python3 -m http.server 8080
````

Output is 

````
sylvain@sylvain-hp:~$ curl localhost:8080 | head -n 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3126  100  3126    0     0   763k      0 --:--:-- --:--:-- --:--:--  763k
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
````

In SFR box at url http://192.168.1.1/network
We can get the local IP address: 	

````
sylvain-hp	192.168.1.92
````

And do

````
sylvain@sylvain-hp:~$ curl 192.168.1.92:8080 | head -n 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3126  100  3126    0     0  1017k      0 --:--:-- --:--:-- --:--:-- 1017k
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>

````

We can use this IP on any device connected to the home network.

### NAT configuration

Our objective is to make this server accessible from the outside.
We will configure our box for this.

In http://192.168.1.1/network/nat do 

````shell script
#	Nom	Protocole	Type	Ports externes	IP de destination	Ports de destination	Activation	
1	hp	TCP	        Port	80	            192.168.1.92	    8080	
````

Then we can get box public IP here:

http://192.168.1.1/state/wan

So that we can target that IP on port 80.

````
curl 109.29.148.109:80 | head -n 5
````


Output is 

````
sylvain@sylvain-hp:~$ curl 109.29.148.109:80 | head -n 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3126  100  3126    0     0   203k      0 --:--:-- --:--:-- --:--:--  203k
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
sylvain@sylvain-hp:~$ 

````
To test it is working use device (phone with 3g) not connected to same local network to check accessible from outside local network!


**Source**: https://www.infraworld.fr/2014/09/30/routage-nat-et-redirection-de-port-sur-box-sfr/

### Firewall config

I will add a firewall 
https://linuxize.com/post/how-to-disable-firewall-on-ubuntu-18-04/

````
sudo ufw reset
sudo ufw enable
````

Now we can not access the app,
We will allow it by adding 

````
sudo ufw allow 8080
````

And access is back.

### other example with Jupyter

Rater than using simple http server we could have used Jupyter.
This can be convenient for this kind of tuto

<!-- use it for aws dojo -->

#### Launch Jupyter

````
pip3 install --upgrade pip
pip3 install jupyter
jupyter notebook 
````

But if doing only this notebook is not accessible via private IP and thus public IP.
We will have to give it as parameter the private IP 

````
jupyter notebook --ip 192.168.1.92 --port 8888
# or actually as discovered in Windows version
jupyter notebook --ip 0.0.0.0 --port 8888
````

**source**: https://stackoverflow.com/questions/39155953/exposing-python-jupyter-on-lan


To make it convenient I recommend to setup a password rather than using a token

````
jupyter notebook password
````

To use bash kernel you have to setup it: https://github.com/takluyver/bash_kernel

````shell script
sudo systemd-resolve --flush-caches  
sudo pip install bash_kernel   
python -m bash_kernel.install
````

For asciidoc generation, pandoc is needed unlike markdown.

#### Configure NAT 

We configure the NAT

```shell script
id	hp-jupyter	TCP	Port	80	192.168.1.32	8888
```

#### Add add firewall rule

````
sudo ufw allow 8888
````

#### Test it

We can nw access via private IP in local network (`192.168.1.32:8888`).
We can also use a device not in local network (phone using 3g) and use public IP like

`109.29.148.109:80`


This enables me to open a terminal in my laptop from my phone to my laptop not connected in same !

#### Note Jupyter on Archlinux VM on windows

``````shell script
sudo pacman -Syu # in particular if 404 error
sudo pacman -S jupyter-notebook
jupyter notebook password # or use token
jupyter notebook --ip 0.0.0.0 --port=8080
``````


Check you forwarded port 8080 to 8980 in VM. Note that ip must be all interface, `127.0.0.1` will work only inside the VM.
Check https://stackoverflow.com/questions/38545198/access-jupyter-notebook-running-on-vm.
We can also edit the configuration.

Open your navigator to ~~http://archlinux:8080/~~ http://127.0.0.1:8980.

We can also use private ip in 192 (given by box or ipconfig/ethernet adapter).

External access seems blocked (windows firewall?, I did not push windows + vm investigations)


## Configure a Dynamic DNS

In previous [example](#Test-it), we were using box public IP: `109.29.148.109:80`.
This IP is dynamic and can change.

Thus we can not provide it to a customer.

To solve this issue we will configure a DynDNS.

Among provider, I decided to use noip: https://my.noip.com/#!/dynamic-dns
It will provide a FQDN (here `scoulomb.ddns.net`) and update the IP dynamically
with the one of the box (when box ip/router change, it trigger a DNS entry update).

<!-- account is s****@gmail.com -->

For this dynamic update configure your router/box to link it to no-ip service (look for dynamic dns in the router configuration).
In my case I use a [NB6 SFR box (doc in French)](https://assistance.sfr.fr/internet-tel-fixe/box-nb6/activer-fonction-dyndns-box-nb6.html).

We go there : http://192.168.1.1/network/ddns ( Home > Réseau v4 > DynDNS)

In my case config is

```shell script
Service: no-ip.com
Nom utilisateur: s****@gmail.com
mdp: #
nom de domaine: scoulomb.ddns.net
```

For other router it is also possible: Cf. Netgear [doc](https://kb.netgear.com/23860/How-do-I-set-up-a-NETGEAR-Dynamic-DNS-account-on-my-NETGEAR-Nighthawk-router)

**Note**: noip proposes to downlaod a soft on your PC, but it would be useful for the private IP.
For box public IP update, it is managed by the router.

Now if we do:

````
sylvain@sylvain-hp:~/myDNS$ nslookup scoulomb.ddns.net 8.8.8.8
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
Name:	scoulomb.ddns.net
Address: 109.29.148.109

``````

We find the box IP.

In box: http://192.168.1.1/state/wan ( Home > Etat > Internet)

It matches: `Adresse IP	109.29.148.109`.


And I can access Jupyter by doing:

[http://scoulomb.ddns.net](http://scoulomb.ddns.net)

To hide the dynamic DNS, 
Then we could define a CNAME (in your nameserver) for instance

````
home 300 IN CNAME scoulomb.ddns.net.
````

So that we can access Jupyter (tested with phone not in private network, wifi off):
[http://home.coulombel.site](http://home.coulombel.site).


<!-- fixed issue 1, https osef, gist + comment ok -->

Applt this to DNS in [part B](6-use-linux-nameserver-part-b.md).