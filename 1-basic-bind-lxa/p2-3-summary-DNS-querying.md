# DNS

````
ssh cloud_user@3.80.8.88
sudo su
yum install -y bind bind-utils
````


## Resolve the IP for google.com

````shell script
host -t a google.com
host -t aaaa google.com
````

````shell script
nslookup google.com
````

````shell script
dig google.com
````
````shell script
Resolve-DnsName -Name google.fr -Server 8.8.8.8
````

## Display the name servers for the google.com domain:

````shell script
host -t ns google.com
````

````shell script
nslookup -type=ns google.com
````

````shell script
dig ns google.com
````

````shell script
Resolve-DnsName -Name google.com -Type ns -Server 8.8.8.8
````

## Resolve the IP address for ns4.google.com

````shell script
host -t a ns4.google.com
host -t aaaa ns4.google.com
````

````shell script
nslookup ns4.google.com
````

````shell script
dig ns4.google.com
````

````shell script
Resolve-DnsName -Name ns4.google.com  -Server 8.8.8.8
````

## Display the mail servers for google.com:
 
````shell script
host -t mx google.com
````

````shell script
nslookup -query=mx google.com
````

````shell script
dig -t mx google.com
````

````shell script
Resolve-DnsName -Name google.com -Type mx -Server 8.8.8.8
````


In `Resolve-DnsName`, I am using google recursive DNS.
