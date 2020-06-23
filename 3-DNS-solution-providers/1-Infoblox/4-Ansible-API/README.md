# InfoBlox Ansible module

## Doc
https://docs.ansible.com/ansible/latest/scenario_guides/guide_infoblox.html

https://www.infoblox.com/wp-content/uploads/infoblox-deployment-guide-infoblox-and-ansible-integration.pdf

## rerequiste

````shell script
sudo pip install infoblox-client

````

## SSH key
Generate your SSH key (used by Ansible) and add them to Authorized key in local host

````
[vagrant@localhost ~]$ ssh-keygen
[vagrant@localhost ~]$ cd .ssh/
[vagrant@localhost .ssh]$ ls
authorized_keys  id_rsa  id_rsa.pub  known_hosts
[vagrant@localhost .ssh]$ cat id_rsa.pub >> authorized_keys
[vagrant@localhost .ssh]$ ssh localhost
Last login: Thu Jul 11 13:19:49 2019 from 10.0.2.2
[vagrant@localhost ~]$ exit
logout
````

## Update your inventory file

````shell script
[vagrant@localhost ~]$ cat /etc/ansible/hosts 127.0.0.1
````

Indeed it is run locally and call API remotely.
