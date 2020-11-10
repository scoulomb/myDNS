# Notes on Docker: application to other use-cases

This is another example where we apply lesson learnt in part D.

## objective

Assume we want to launch a non regression job only after a deployment of an API server is performed in a `Jenkinsfile`.

## Solution 0: make jenkins sleep 

## Solution 1: make sleep in job

Override job docker entrypoint/k8s command as done here to sleep while the code is loaded and provide version defined in Jenkins file
<!-- what we did initially lb-->

````shell script
def version="1.2
sh "./path/to/oc create job api-after-load-non-regression-${version} --from=cronjob/api-non-regression -- /bin/sh -c 'sleep 60 && launch.sh $version publish des'"
````


Here we override the job entrypoint.
This is what we explained in [part d](6-use-linux-nameserver-part-d.md#kubernetes-link).

Also here `/bin/sh -c`  is useless as we do not do env var substitution of variable defined in the Dockerfile but the one in Jenkins file (shell calling the Docker).
In [solution 2](#solution-2-use-deployment-rollout), note that it was removed as a proof.

This is similar to the case in [part d](6-use-linux-nameserver-part-d.md#ip-env-var-defined-outside-and-no-shell-usage-warning)

## Assume we have in Openshift template/Helm:

````shell script
    - name: my-non-reg
      command: ["/bin/sh", "-c", "/bin/sh launch.sh ${DOCKER_IMAGE_VERSION} publish $NAMESPACE"]
      env:
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
````

Note here:
- `${DOCKER_IMAGE_VERSION}` is an Openshift template var
- In command we need for  `/bin/sh", "-c"` for environment var `$NAMESPACE`
Similar to that case in [part D](6-use-linux-nameserver-part-d.md#ip-as-container-env-var-and-shell-usage-ok).
Note kube synthax is exec form but consistent with fact overrides use exec form.
And we had seen that  `/bin/sh -c '/bin/sh -c "echo $PWD"'` is [working](6-use-linux-nameserver-part-d.md#note-that-system-environment-var-are-inherited).

- However the second `/bin/sh` is useless and will prove it

````shell script
ssh sylvain@109.29.148.109

mkdir /tmp/docker

echo '#!/bin/bash 
 for i; do 
    echo $i 
 done
' > /tmp/docker/launch.sh


echo 'FROM ubuntu
COPY launch.sh /launch.sh
RUN chmod u+x /launch.sh
' > /tmp/docker/test.Dockerfile

sudo docker build /tmp/docker -f /tmp/docker/test.Dockerfile -t test

sudo docker run --name=optionalname --env NAMESPACE="scoulomb-ns" test  /bin/sh -c 'echo $NAMESPACE'
sudo docker run --env NAMESPACE="scoulomb-ns" test  cat launch.sh


sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/bin/sh /launch.sh 1 publish $NAMESPACE'
sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/launch.sh 1 publish $NAMESPACE'

````

Output is 

````shell script
sylvain@sylvain-hp:~$ sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/bin/sh /launch.sh 1 publish $NAMESPACE'
1
publish
scoulomb-ns
sylvain@sylvain-hp:~$ sudo docker run --env NAMESPACE="scoulomb-ns" test  /bin/sh -c '/launch.sh 1 publish $NAMESPACE'
1
publish
scoulomb-ns
sylvain@sylvain-hp:~$
````

To be rigorous, as explained in  [part d - Kubectl create job](6-use-linux-nameserver-part-d.md#kubectl-create-job).
When creating a job when we use  kubectl, it creates k8s command and same in our manifest. k8s command is Docker ENTRYPOINT. 
Thus we should use docker ENTRYPOINT so to be equivalent and not docker CMD as done above.
In Docker CLI it is `--entrypoint`, however when doing this we have some quote issue with docker run and shell. So we will not do it.

<!-- pr 71 -->

## Solution 2: use deployment rollout

This is the solution which we advise.

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
def version = "42.1"
// Trigger non regression job after load
sh "./path/to/oc rollout status dc automation-server; echo \$?"
sh "./path/to/oc create job non-regression-afer-load-${version} --from=cronjob/automation-api-non-regression -- 'launch.sh $version publish des'"
````



Which is perfect 

I used `;` and not `&&` for this reason:
https://stackoverflow.com/questions/5130847/running-multiple-commands-in-one-line-in-shell

<!--
For early merge:
proj settings: default reviewer and repo settings: merge check
dns pr#70
-->

Having following error

````shell script
/oc rollout status dc dns-automation-server
Waiting for rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for rollout to finish: 2 out of 3 new replicas have been updated...
error: watch closed before Until timeout
script returned exit code 1
````
It seems to be a known issue
https://github.com/kubernetes/kubernetes/issues/40224

But if the version of the kubectl we use does not have tinmeout option it will not work

````shell script
kubectl rollout status deployment/app --namespace=app --timeout=60s
````


<!-- relaunching twice and it worked so we can keep it -->

If reproducing we can combine with solution and make Jenkins sleep, we know that a rollout is taking ~3min.

Finally we can Simplify removing entrypoint override in CLI as can use manifest override
<!-- dns pr#72 -->

sh "./path/to/oc create job non-regression-afer-load-${version} --from=cronjob/automation-api-non-regression"

This will enable to test modification made in [section](#assume-we-have-in-openshift-templatehelm).
<!-- made in pr#71 -->
And avoid future error `error: cannot specify --from and command` from [part d](6-use-linux-nameserver-part-d.md#kubectl-create-job).

<!--
pr 70-71-72 
impacts only end of Jenkins file + cj template if needed to reproduce
 d + applications of d are concluded -->