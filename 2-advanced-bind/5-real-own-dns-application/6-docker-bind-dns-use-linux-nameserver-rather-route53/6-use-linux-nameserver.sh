# !/bin/sh
# Did not work initially on specific zone coulombel.it.
# Start from scratch and work with both zone coulombel.it and yop.coulombel.it (subzone delegation)
# Keep coulombel.it as example with tld

echo "== Configure firewall if needed"
sudo ufw allow from any to any port 53 proto udp
sudo ufw allow from any to any port 32048 proto udp

echo "== Build DNS docker image"
script_path=$(dirname "$0")
echo $script_path
set -o xtrace
sudo docker build -f dns-ubuntu.Dockerfile -t dns-ubuntu $script_path
# use --no-cache if apt-get issue

echo "== Clean-up"
sudo kubectl delete po --all --force --grace-period=0
sudo kubectl delete svc --all

echo "== Start pod and expose it as a NodePort"
sudo kubectl run ubuntu-dns --image=dns-ubuntu --restart=Never --image-pull-policy=Never 

# we can not specify a specific nodeport with this command
# sudo kubectl expose pod ubuntu-dns --port 53 --protocol=UDP --type=NodePort
# unlike with https://stackoverflow.com/questions/43935502/kubernetes-nodeport-custom-port/43944385
# which gives with newer version
# sudo kubectl create service nodeport  ubuntu-dns --tcp=53:53 --node-port 32048 -o yaml --dry-run=client
# But we can not specify UDP with that command
# So I will do sudo
# kubectl expose pod ubuntu-dns --port 53 --protocol=UDP --type=NodePort -o yaml --dry-run=client
# and generate a file with node port added
temp_file=$(sudo mktemp)
sudo chmod 777 ${temp_file}
sudo cat << FIN > ${temp_file}
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    run: ubuntu-dns
  name: ubuntu-dns
spec:
  ports:
  - port: 53
    protocol: UDP
    targetPort: 53
    nodePort: 32048
  selector:
    run: ubuntu-dns
  type: NodePort
status:
  loadBalancer: {}
FIN
sudo cat ${temp_file}
sudo kubectl apply -f ${temp_file}
sudo rm $temp_file


set -o xtrace
sleep 5


# https://stackoverflow.com/questions/2853803/how-to-echo-shell-commands-as-they-are-executed

echo "== Test"

echo "=== Get service cluster IP and NodePort"
sudo kubectl get svc ubuntu-dns
# As suggested in K8s website PR
export DNS_SVC_CLUSTER_IP=$(sudo kubectl get svc ubuntu-dns -o=jsonpath='{.spec.clusterIP}')
# even more needed if we do not specify the nodeport when exposing the service
export DNS_SVC_NODE_PORT=$(sudo kubectl get svc ubuntu-dns -o=jsonpath='{.spec.ports[0].nodePort}')
export DNS_POD_IP=$(sudo kubectl get pod ubuntu-dns -o=jsonpath='{.status.podIP}')

echo $DNS_SVC_CLUSTER_IP
echo $DNS_SVC_NODE_PORT
echo $DNS_POD_IP

echo "=== Test DNS inside DNS container"
sudo kubectl exec ubuntu-dns  -- nslookup scoulomb.coulombel.it 127.0.0.1

echo "=== Test DNS via POD IP from node"
nslookup scoulomb.coulombel.it  $DNS_POD_IP # port is 53 by default

echo "=== Test DNS via service cluster IP from node"
nslookup scoulomb.coulombel.it  $DNS_SVC_CLUSTER_IP # port is 53 by default

echo "=== Test DNS via POD IP from another container in a different pod"
# https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/4-Run-instructions-into-a-container.md#but-we-could-inject-command-directly
sudo kubectl run dns-ubuntu-client-test --rm -it --image=dns-ubuntu --restart=Never --image-pull-policy=Never  --env="DNS_POD_IP=$DNS_POD_IP" --command nslookup scoulomb.coulombel.it $DNS_POD_IP

echo "=== Test DNS via service cluster IP from another container in a different pod"
# https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/4-Run-instructions-into-a-container.md#but-we-could-inject-command-directly
sudo kubectl run dns-ubuntu-client-test --rm -it --image=dns-ubuntu --restart=Never --image-pull-policy=Never  --env="DNS_SVC_CLUSTER_IP=$DNS_SVC_CLUSTER_IP" --command nslookup scoulomb.coulombel.it $DNS_SVC_CLUSTER_IP

echo "=== Test DNS via service cluster IP using service DNS name from another container in a different pod"
sudo kubectl run dns-ubuntu-client-test --rm -it --image=dns-ubuntu --restart=Never --image-pull-policy=Never --command nslookup scoulomb.coulombel.it ubuntu-dns
# Note we can only use DNS service name from another pod
# Here in my experience it could not work (STOP OK)

echo "=== Test DNS via service cluster IP using service generated env var from another container in a different pod"
# This does not subtitute var we should do
# sudo kubectl run dns-ubuntu-client-test --rm -it --image=dns-ubuntu --restart=Never --image-pull-policy=Never --command nslookup scoulomb.coulombel.it $UBUNTU_DNS_SERVICE_HOST
# We should do
# sudo kubectl run dns-ubuntu-client-test --rm -it --image=dns-ubuntu --restart=Never --image-pull-policy=Never --command -- bash
# nslookup scoulomb.coulombel.it $UBUNTU_DNS_SERVICE_HOST && exit (STOP OK)

echo "===  Test DNS via service NodePort using localhost"
nslookup -port=$DNS_SVC_NODE_PORT scoulomb.coulombel.it 127.0.0.1

echo "=== Test DNS via service NodePort using private IP"
private_eth_range=$(ip addr show | grep eno1 | grep 192 | awk '{print $2}')
private_ip=${private_eth_range::-3}
nslookup -port=$DNS_SVC_NODE_PORT scoulomb.coulombel.it $private_ip

echo "=== Test DNS via service NodePort using natted public IP via public IP directly or dynamic DNS"

nslookup scoulomb.coulombel.it scoulomb.ddns.net
# or use BOX IP directly like 109.29.148.109
BOX_PUBLIC_IP=$(nslookup scoulomb.ddns.net  | grep "Address:"  | sed -n 2p | awk '{print $2}')
nslookup scoulomb.coulombel.it $BOX_PUBLIC_IP

echo "=== Test Github page"
nslookup coulombel.it scoulomb.ddns.net

set +x && set +v
