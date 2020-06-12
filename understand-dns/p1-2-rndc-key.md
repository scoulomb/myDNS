# DNS 

## DNS: Working with RNDC Keys

<details>
<summary>Click to expand..</summary>
<p>

We will be working with RNDC. We will be recreating an RNDC key, and linking it to the named configuration, then we'll need to show that we have create a new configuration and that DNS queries are being cached on localhost


Before We Begin
To get started, we need to log in to our lab server using the cloud_user and provided password. Note that we need to change <"provided lab server IP"> to the IP provided by the lab credentials:

ssh cloud_user@<"public server IP">
Password:
After, we need to use sudo -i to gain root access in the terminal:

````
sudo -i
````


Search for the id:

id

Install the bind and bind-utils packages
Install the bind and bind-utils packages using yum:

````
yum install -y bind bind-utils
````
Added note that rndc key are not created at that step

````
rm /etc/rndc.key
rm: cannot remove ‘/etc/rndc.key’: No such file or directory
````

Start and enable the named service:
````
systemctl start named
````

After systemd start they are 

````
[root@server1 ~]# ls /etc | grep rndc
rndc.key
````
then
````
systemctl enable named
````

All above is as in section 1.

Review the key we created (created at service start by named see above):

````
ls -al /etc/rndc.key
````

Open the file with cat to see our secret strand:

````
cat /etc/rndc.key
````

Recreate the RNDC key and configuration file
Remove the rndc.key file, and enter y when prompted:

````
rm /etc/rndc.key
````

Double-check it's removed using:
````
rndc reload
````
We get back a message saying it wasn't found.

````
[root@server1 ~]# rndc reload
rndc: neither /etc/rndc.conf nor /etc/rndc.key was found
````

Stop the named service.

````
systemctl stop named
````

Generate the key and connect it to our configuration file.

````
rndc-confgen -r /dev/urandom > /etc/rndc.conf
````

````
[root@server1 ~]# ls /etc | grep rndc
rndc.conf
````

Link the RNDC configuration to the named Configuration
Open the `/etc/rndc.conf` file with vim:
or with `more /etc/rndc.conf`
Copy the section under # End of rndc.conf

Open the `/etc/named.conf` file for editing with vim.

`vim /etc/named.conf`
Paste the copied section into `/etc/named.conf` just before the include statements and delete the # signs at the beginning of each line except for the line beginning with # Use.
Save the document using :wq~.
Next, to check that there are no syntax errors, use `named-checkconf`.
Next start and then reload the service:
````
systemctl start named
rndc reload
````

Start the named and Test the RNDC Configuration
Start the named service.
````
systemctl start named
````
Test the configuration to ensure records are being cached on the localhost.
nslookup www.google.com 127.0.0.1

Conclusion
we reconnect RNDC key to to the named service!

### Exploration

If now I do 
````
[root@server1 ~]# rm -f /etc/rndc.key
[root@server1 ~]# rndc reload
server reload successful
````

Because the key is in named ans conf file !

Let's detroy and restart fresh environment and perform the same steps as in lab 

We will see that

````
[root@server1 ~]# ll /etc | grep rndc
-rw-r--r--.  1 root root      479 Jun 10 09:28 rndc.conf
-rw-r-----.  1 root named     100 Jun 10 09:28 rndc.key
````


````
[root@server1 ~]# cat /etc/rndc.conf /etc/rndc.key
# Start of rndc.conf
key "rndc-key" {
        algorithm hmac-md5;
        secret "U9CVJCm5OozxaPl0wmKDkQ==";
};

options {
        default-key "rndc-key";
        default-server 127.0.0.1;
        default-port 953;
};
# End of rndc.conf

# Use with the following in named.conf, adjusting the allow list as needed:
# key "rndc-key" {
#       algorithm hmac-md5;
#       secret "U9CVJCm5OozxaPl0wmKDkQ==";
# };
#
# controls {
#       inet 127.0.0.1 port 953
#               allow { 127.0.0.1; } keys { "rndc-key"; };
# };
# End of named.conf
key "rndc-key" {
        algorithm hmac-sha256;
        secret "58DkPAJNSa3r3SUmF1xeD3FACgPN1DBu/hgOFKFRlwU=";
};
````

It regenerates a key from conf !


Now if I delete it

````
[root@server1 ~]# rm -f /etc/rndc.key
[root@server1 ~]# rndc reload
server reload successful
[root@server1 ~]#
````

It works as it has has also the conf
Editing the key directly does not seem to work so we have to use this technique.

<!--
Section OK
-->

</p>
</details>  
