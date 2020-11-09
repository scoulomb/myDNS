# Notes on Docker: application to other use-cases

This is another example where we apply lesson learnt in part D.

## objective

Assume we want to launch a non regression job only after a deployment of an API server is performed in a `Jenkinsfile`.

## Solution 0: make jenkins sleep 

## Solution 1: make sleep in job

Override job docker entrypoint/k8s command as done here to sleep while the code is loaded and provide version define in Jenkins file
<!-- what we did initially lb-->

````shell script
def version="1.2
sh "./path/to/oc create job api-after-load-non-regression-${version} --from=cronjob/api-non-regression -- /bin/sh -c 'sleep 60 && launch.sh $version publish des'"
````


Here we ovverride the job entrypoint.
This is what we explained in [part D](6-use-linux-nameserver-part-d.md#kubernetes-link).

Also here `/bin/sh -c`  is usless as we do not do env var substitution of variable defined in the Dockerfile but the one in Jenkins file (shell calling the Docker).
This is similar to the case in [part d](6-use-linux-nameserver-part-d.md#ip-env-var-defined-outside-and-no-shell-usage-warning)

Assume we have in Openshift template/Helm:

````shell script
    - name: my-non-reg
      command: ["/bin/sh", "-c", "/bin/sh launch.sh ${DOCKER_IMAGE_VERSION} publish $NAMESPACE"]
      env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
````

Note here we need for  `/bin/sh", "-c"` for environment var `$NAMESPACE`, but the first one is useless.
Similar to that case in [part D](6-use-linux-nameserver-part-d.md#ip-as-container-env-var-and-shell-usage-ok).
TODO: fix

## Solution 2: use deployment rollout

We will use alpine, to show an example

=> unlike job we can not override docker entrypoint / k8s command with kubectl as we had done [in paert d - job entrypoint override](6-use-linux-nameserver-part-d.md#kubernetes-link):
As explained here, we have to define a manifest:
https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#create-deployment


So let's do it 

````shell script
k delete deployment alpine-deployment 
k create deployment alpine-deployment --image=alpine --dry-run=client -o yaml > out.txt

echo ' 
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: alpine-deployment
  name: alpine-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: alpine-deployment
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: alpine-deployment
    spec:
      containers:
      - image: alpine
        name: alpine
        command:
        - /bin/sleep
        - "3600"
        resources: {}
status: {}' > alpine-deployment.yaml
k create -f alpine-deployment.yaml
https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#creating-a-deployment
````

Then we can call the blocking command:

````shell script
sudo kubectl rollout status deployment alpine-deployment

# This is a blocking call and can even get the status 
echo $?
````


In Openshift similar command exist for `dc`

````shell script
oc rollout status dc automation-server ; echo $?
````

Thus

````shell script
sh "./path/to/oc rollout status dc automation-server; echo \$?"
````

Which is perfect 

I used `;` and not `&&` for this reason:
https://stackoverflow.com/questions/5130847/running-multiple-commands-in-one-line-in-shell

<!--
For early merge:
proj settings: default reviewer and repo settings: merge check
dns pr#70
-->