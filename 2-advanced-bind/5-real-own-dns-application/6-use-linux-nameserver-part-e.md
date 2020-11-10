
## NEXT

````shell script
# sudo docker run dns-ubuntu p 32048:53


# piege: every after image is ignore, the port forwarding is udp for dns !!
# https://docs.docker.com/config/containers/container-networking/
# $ sudo docker run -p 32048:53/udp --name mydns_1 dns-ubuntu
# $ nslookup -port=32048 scoulomb.coulombel.it 127.0.0.1
# $ sudo docker exec mydns_1  /bin/sh -c "nslookup scoulomb.coulombel.it 127.0.0.1"

expose en udp

# lien avec docker-doctor docker run and kunectl run --
# and docker run to launch live and exit cntainer with kubectl ckad
# lien myk8s entrypont and command
# doc lancer docker seul dans k8s et vorir erreur (faire appendice)
````
