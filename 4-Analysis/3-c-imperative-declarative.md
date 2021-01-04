# Declarative and Imperative approach 

This extends this [comment](3-a-towards-a-k8s-like-api-explore-k8s-api.md#apply-vs-create) and previous sections 3.

This is based on question asked on [stackoverflow: why kubernetes rest api is imperative](https://stackoverflow.com/questions/65225688/why-kubernetes-rest-api-is-imperative).

## Definition

### Imperative

From https://en.wikipedia.org/wiki/Imperative_programming
> imperative programming is a programming paradigm that uses statements that change a program's state.
> In much the same way that the imperative mood in natural languages expresses commands,
> an imperative program consists of commands for the computer to perform. 
> Imperative programming focuses on describing how a program operates.
> The term is often used in contrast to declarative programming, which focuses on what the program should accomplish without specifying how the program should achieve the result. 

### Declarative 

From https://en.wikipedia.org/wiki/Declarative_programming
> declarative programming is a programming paradigm—a style of building the structure and elements of computer programs—that 
> expresses the logic of a computation without describing its control flow
> [...]
> Declarative programming is a non-imperative style of programming in which programs describe their desired results without 
> explicitly listing commands or steps that must be performed.

<!--
Example: decl vs imp
Phone on the table <=> Move toward the table, take phone with hand from my pocket, drop it on on the table
-->

### Rephrasing 

- An **imperative** API is based around the concept of **an ordered list of commands** to arrive at a given state.
- A **declarative** API is based around the concept of **requesting the desired state**, leaving the list of commands up to the API.

### idempotency

From https://en.wikipedia.org/wiki/Idempotence

> Idempotence is the property of certain operations in mathematics and computer science whereby they can be applied multiple times without changing the result beyond the initial application. 

From https://developer.mozilla.org/en-US/docs/Glossary/Idempotent

> An HTTP method is idempotent if an identical request can be made once or several times in a row with the same effect while leaving the server in the same state. 
> In other words, an idempotent method should not have any side-effects (except for keeping statistics).
> Implemented correctly, the GET, HEAD, PUT, and DELETE methods are idempotent, but not the POST method.
> All safe methods are also idempotent.

> To be idempotent, **only the actual back-end state of the server is considered, the status code returned by each request may differ: 
> the first call of a DELETE will likely return a 200, while successive ones will likely return a 404.**

> Another implication of DELETE being idempotent is that developers should not implement RESTful APIs with a delete last entry functionality using the DELETE method.

See also: https://youtu.be/UaKZ4wKytcA 

### Comments on POST and retry

Idempotency is more natural with a declarative approach.

However a POST can not be idempotent.

From https://en.wikipedia.org/wiki/POST_(HTTP)

> Per RFC 7231, the POST method is not idempotent, meaning that multiple identical requests might not have the same effect than transmitting the request only once. POST is therefore suitable for requests which change the state each time they are performed, for example submitting a comment to a blog post or voting in an online poll. GET is defined to be nullipotent, with no side-effects, and idempotent operations have "no side effects on second or future requests".[10][11] For this reason, web crawlers such as search engine indexers normally use the GET and HEAD methods exclusively, to prevent their automated requests from performing such actions.
> However, there are reasons why POST is used even for idempotent requests, notably if the request is very long. Due to restrictions on URLs, the query string the GET method generates may become very long, especially due to percent-encoding.[10]

See also tips to make it idempotent for retry: https://medium.com/@saurav200892/how-to-achieve-idempotency-in-post-method-d88d7b08fcdd

This what AWS is doing:

### Comments on AWS ELB 

Here is their documentation : https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_CreateLoadBalancer.html

And a sample request to Create an Internet-facing load balancer

````shell script
https://elasticloadbalancing.amazonaws.com/?Action=CreateLoadBalancer
&Name=my-load-balancer
&Subnets.member.1=subnet-8360a9e7
&Subnets.member.2=subnet-b7d581c0
&Version=2015-12-01
&AUTHPARAMS
````

Their API is more imperative.
Note the verb can be a GET or POST in example above, it is a query request.

From, https://docs.aws.amazon.com/elasticloadbalancing/2012-06-01/APIReference/elb-api.pdf, p110

> Elastic Load Balancing provides APIs that you can call by submitting a Query request. Query requests are
HTTP or HTTPS requests that use the HTTP verb GET or POST and a Query parameter named Action or
Operation that specifies the API you are calling.
Calling the API using a Query request is the most direct way to access the web service, but requires that
your application handle low-level details such as generating the hash to sign the request, and error
handling. The benefit of calling the service using a Query request is that you are assured of having access
to the complete functionality of the API.
Note
The Query interface used by AWS is similar to REST, but does not adhere completely to the REST
principles.

See also https://docs.aws.amazon.com/AWSEC2/latest/APIReference/Query-Requests.html

> For each Amazon EC2 API action, you can choose whether to use GET or POST

We can see we can modify ELB attributes.

Create query request is idempotent: from  https://docs.aws.amazon.com/elasticloadbalancing/latest/APIReference/API_CreateLoadBalancer.html

> This operation is idempotent, which means that it completes at most one time. If you attempt to create multiple load balancers with the same settings, each call succeeds.

Therefore they offer a imperative API with idempotency

Meaning that when creating several time the same object,
If this has the same id/name and config it does not fail.
Same name but different config → 400.

## Kubernetes

### REST API

See API reference:
- https://kubernetes.io/docs/reference/using-api/
- https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.20/

Kubernetes REST API is declarative. Why?

This requires to run `kubectl proxy` first.


```shell script

k delete ns testapi
# or
k delete po,deployment --all -n testapi --force --grace-period=0

k create ns testapi

curl -X POST -H 'Content-Type: application/yaml' --data '
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-example
spec:
  replicas: 3
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14
        ports:
        - containerPort: 80
' http://127.0.0.1:8080/apis/apps/v1/namespaces/testapi/deployments/
```

The Kubernetes API is **declarative** in the sense that you always specify **what** you want, e.g. `replicas: 2` instead of e.g. `create 2 replicas` that would be the case in an _imperative_ API. The controllers then "drives" the state to "what" you specified in a reconciliation loop.

Submitting this payload a second time leads to a `409`, but the API is still declarative.

For example if I update the deployment to have 5 replicas with a `PUT`.

````shell script
curl -X PUT -H 'Content-Type: application/yaml' --data ' # change verb
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-example
spec:
  replicas: 5 # change #replicas
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14
        ports:
        - containerPort: 80
' http://127.0.0.1:8080/apis/apps/v1/namespaces/testapi/deployments/deployment-example # name in endpoint
````

We can see new deployment

````shell script
➤ k get po -n testapi
NAME                                 READY   STATUS    RESTARTS   AGE
deployment-example-d9d8cf5c7-8d86j   1/1     Running   0          28s
deployment-example-d9d8cf5c7-9g844   1/1     Running   0          94s
deployment-example-d9d8cf5c7-hrzmw   1/1     Running   0          94s
deployment-example-d9d8cf5c7-nzc8m   1/1     Running   0          94s
deployment-example-d9d8cf5c7-vprsk   1/1     Running   0          28s
````

And resubmitting the same manifest with PUT is woking. 
A `PUT` with endpoint as  `http://127.0.0.1:8080/apis/apps/v1/namespaces/testapi/deployments` (root of deployment) is not working.

And clean-up 

````shell script
k delete ns testapi
# or
k delete po --all -n testapi --force --grace-period=0
````

Similarly AS3 is declarative because we declare the config: https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/http-methods.html
And do create a pool and then attach a virtual server to a pool.
As they do not have a PUT, their POST is a kind of idempotent, and does not return conflict.

### PUT and POST at POD level


If I do

````shell script
k create ns testapi

curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods \
 -d '{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api-test","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}' 

curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods \
 -d '{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api-test","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}' 

# Note name is added otherwise method not allowed as as described in 3-a
# Taking POST and change verb to PUT and add pod name in endpoint is not sufficient
curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api-test \
 -d '{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api-test","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}' 

k delete ns testapi
````

output I got the second time is

````shell script
➤ curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods \
   -d '{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api-test","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "pods \"nginx-via-api-test\" already exists",
  "reason": "AlreadyExists",
  "details": {
    "name": "nginx-via-api-test",
    "kind": "pods"
  },
  "code": 409
}⏎
````

and results for `PUT`

````shell script
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "Pod \"nginx-via-api-test\" is invalid: spec: Forbidden: pod updates may not change fields other than `spec.containers[*].image`, `spec.initContainers[*].image`, `spec.activeDeadlineSeconds` or `spec.tolerations` (only additions to existing tolerations)\n  co
````

Already seen there: https://github.com/scoulomb/myk8s/blob/master/Volumes/secret-doc-deep-dive.md#can-we-update-environment-var-when-not-using-a-secret

Solutions are:
- solution 1: Work at deployment level (as done [there](#rest-api))
- solution 2: Or export pod,delete and recreate (POST, k create/apply) (as some added fields are immutable) (as suggested here: https://github.com/kubernetes/kubernetes/issues/24913)
- solution 3: Deletion is actually not necessary: export pod, and re-apply (PUT, k apply and not create) (as some added fields are immutable) 

We used solution 3 in section [3a](3-a-towards-a-k8s-like-api-explore-k8s-api.md#put-to-modify-a-pod)

````shell script
k get pods nginx-via-api-test -n testapi -o json | jq 'del(.metadata.namespace,.metadata.resourceVersion,.metadata.uid,.metadata.managedFields,.status) | .metadata.creationTimestamp=null' > poddata.json
````

And apply via API

````
curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api-test  -d @poddata.json
````

And this is working.

Can I bypass the `POST`

````shell script
k delete po --all -n testapi
curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api-test  -d @poddata.json
curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods -d @poddata.json
````

output is 


````shell script
➤ curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api-test  -d @poddata.json
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "pods \"nginx-via-api-test\" not found",
  "reason": "NotFound",
  "details": {
    "name": "nginx-via-api-test",
    "kind": "pods"
  },
  "code": 404
}⏎
[15:28] ~
➤ curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods -d @poddata.json
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "the server does not allow this method on the requested resource",
  "reason": "MethodNotAllowed",
  "details": {

  },
  "code": 405
}⏎
````


### Delete returns a 404

````shell script
 curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods/tuti
````

output 

````shell script
➤ curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods/tuti
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "pods \"tuti\" not found",
  "reason": "NotFound",
  "details": {
    "name": "tuti",
    "kind": "pods"
  },
  "code": 404
}⏎
````

Server state is idempotent, not the status code!

## What about the `kubectl`?

From:
- https://kubernetes.io/docs/tasks/manage-kubernetes-objects/imperative-config/ 
- which is directing to https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/


The `kubectl` command-line tool supports several different ways to create and manage
Kubernetes objects.


| Management technique             | Operates on          |Recommended environment | Supported writers  | Learning curve |
|----------------------------------|----------------------|------------------------|--------------------|----------------|
| Imperative commands              | Live objects         | Development projects   | 1+                 | Lowest         |
| Imperative object configuration  | Individual files     | Production projects    | 1                  | Moderate       |
| Declarative object configuration | Directories of files | Production projects    | 1+                 | Highest        |

It is not recommended to mix.


  

### Imperative commands

When using imperative commands, a user operates directly on live objects
in a cluster. The user provides operations to
the `kubectl` command as arguments or flags.


Run an instance of the nginx container by creating a Deployment object:

```sh
k create deployment nginx --image nginx
k scale deployment nginx --replicas=5
```

See https://github.com/scoulomb/myk8s/blob/master/Master-Kubectl/1-kubectl-create-explained-ressource-derived-from-pod.md#create-deployment



### Imperative object configuration

In imperative object configuration, the kubectl command specifies the
operation (create, replace, etc.), optional flags and at least one file
name. The file specified must contain a full definition of the object
in YAML or JSON format.


Create the objects defined in a configuration file:

```sh
kubectl create -f nginx.yaml
```

Delete the objects defined in two configuration files:

```sh
kubectl delete -f nginx.yaml -f redis.yaml
```

Update the objects defined in a configuration file by overwriting
the live configuration:

```sh
kubectl replace -f nginx.yaml
```


### Declarative object configuration

When using declarative object configuration, a user operates on object
configuration files stored locally, however the user does not define the
operations to be taken on the files. Create, update, and delete operations
are automatically detected per-object by `kubectl`. This enables working on
directories, where different operations might be needed for different objects.


Declarative object configuration retains changes made by other
writers, even if the changes are not merged back to the object configuration file.
See merge patch calculation: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/#merge-patch-calculation

Process all object configuration files in the `configs` directory, and create or
patch the live objects. You can first `diff` to see what changes are going to be
made, and then apply:


#### Experience 1

Reusing [same manifest defined in "rest api" section where we add labels](#rest-api), we create several deployment versions ([v1](v1), [v2](v2), [v3](v3)) used in example below.

```shell script
k delete ns testapi --force --grace-period=0
k create ns testapi
````

Show we can apply a file only

````shell script
k apply -f  4-Analysis/3-c-imperative-declarative/v1/deployment1.yaml -n testapi
k delete deploy --all -n testapi
````

we can apply a folder, scale with imperative, but a reapply set back to initial state

````shell script
k apply -f 4-Analysis/3-c-imperative-declarative/v1 -n testapi
k scale deployment.apps/deployment-example --replicas=25 -n testapi
````

This operation rollout a deployment .
See [deployment rollout](../2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d-other-applications.md#solution-2-use-deployment-rollout)

````shell script
k rollout status deployment deployment-example -n testapi
````

````shell script
➤ k rollout status deployment deployment-example -n testapi
Waiting for deployment "deployment-example" rollout to finish: 3 of 25 updated replicas are available...
Waiting for deployment "deployment-example" rollout to finish: 4 of 25 updated replicas are available...
Waiting for deployment "deployment-example" rollout to finish: 5 of 25 updated replicas are available...
Waiting for deployment "deployment-example" rollout to finish: 6 of 25 updated replicas are available..
````

But it did not trigger a new rs

````shell script
k describe deployment.apps/deployment-example -n testapi | grep -A 15 Events
````
as it outputs

````shell script
➤ k describe deployment.apps/deployment-example -n testapi | grep -A 15 Events
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  100s  deployment-controller  Scaled up replica set deployment-example-d9d8cf5c7 to 3
  Normal  ScalingReplicaSet  92s   deployment-controller  Scaled up replica set deployment-example-d9d8cf5c7 to 25
````

An interesting fact if we do 

````shell script
➤ k get deployment deployment-example -n testapi -o yaml | grep replicas
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"proj":"scoulomb"},"name":"deployment-example","namespace":"testapi"},"spec":{"replicas":3,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"nginx"}},"template":{"metadata":{"labels":{"app":"nginx"}},"spec":{"containers":[{"image":"nginx:1.14","name":"nginx","ports":[{"containerPort":80}]}]}}}}
        f:replicas: {}
        f:replicas: {}
  replicas: 25
  replicas: 25
````

we have in `metadata.annotations.kubectl.kubernetes.io/last-applied-configuration` a replica count to 3, whereas we have 25 in spec.
Because last applied configuration with `apply` is 3.

And we can come back to initial state

````shell script
k apply -f 4-Analysis/3-c-imperative-declarative/v1  -n testapi
k rollout status deployment deployment-example -n testapi
k describe deployment.apps/deployment-example -n testapi | grep -A 15 Events
k get deployment deployment-example -n testapi -o yaml | grep replicas
````


output is 

````shell script
➤ k describe deployment.apps/deployment-example -n testapi | grep -A 15 Events
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  2m42s  deployment-controller  Scaled up replica set deployment-example-d9d8cf5c7 to 3
  Normal  ScalingReplicaSet  2m34s  deployment-controller  Scaled up replica set deployment-example-d9d8cf5c7 to 25
  Normal  ScalingReplicaSet  25s    deployment-controller  Scaled down replica set deployment-example-d9d8cf5c7 to 3
````

Doing 

````shell script
➤ k get deployment deployment-example -n testapi -o yaml | grep replicas
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"proj":"scoulomb"},"name":"deployment-example","namespace":"testapi"},"spec":{"replicas":3,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"nginx"}},"template":{"metadata":{"labels":{"app":"nginx"}},"spec":{"containers":[{"image":"nginx:1.14","name":"nginx","ports":[{"containerPort":80}]}]}}}}
        f:replicas: {}
        f:replicas: {}
  replicas: 3
  replicas: 3
````

Shows replicas are aligned.

We can update to v2 where we change container port and replicas to 10 of deployment 1.

````shell script
k diff -f 4-Analysis/3-c-imperative-declarative/v2 -n testapi
k apply -f 4-Analysis/3-c-imperative-declarative/v2 -n testapi
k rollout status deployment deployment-example -n testapi
k describe deployment.apps/deployment-example -n testapi | grep -B 4 -A 15 Events
````

output is 

````shell script
➤ k rollout status deployment deployment-example -n testapi
Waiting for deployment "deployment-example" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "deployment-example" rollout to finish: 5 out of 10 new replicas have been updated...
Waiting for deployment "deployment-example" rollout to finish: 5 out of 10 new replicas have been updated...
[...]
Waiting for deployment "deployment-example" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "deployment-example" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "deployment-example" rollout to finish: 8 of 10 updated replicas are available...
Waiting for deployment "deployment-example" rollout to finish: 9 of 10 updated replicas are available...

➤ k describe deployment.apps/deployment-example -n testapi | grep -B 4 -A 15 Events
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   deployment-example-856f4d77d5 (10/10 replicas created)
Events:
  Type    Reason             Age                     From                   Message
  ----    ------             ----                    ----                   -------
  Normal  ScalingReplicaSet  6m41s                   deployment-controller  Scaled up replica set deployment-example-d9d8cf5c7 to 3
  Normal  ScalingReplicaSet  6m33s                   deployment-controller  Scaled up replica set deployment-example-d9d8cf5c7 to 25
  Normal  ScalingReplicaSet  4m24s                   deployment-controller  Scaled down replica set deployment-example-d9d8cf5c7 to 3
  Normal  ScalingReplicaSet  2m27s                   deployment-controller  Scaled up replica set deployment-example-d9d8cf5c7 to 10
  Normal  ScalingReplicaSet  2m27s                   deployment-controller  Scaled up replica set deployment-example-856f4d77d5 to 3
  Normal  ScalingReplicaSet  2m27s                   deployment-controller  Scaled down replica set deployment-example-d9d8cf5c7 to 8
  Normal  ScalingReplicaSet  2m27s                   deployment-controller  Scaled up replica set deployment-example-856f4d77d5 to 5
  Normal  ScalingReplicaSet  2m23s                   deployment-controller  Scaled down replica set deployment-example-d9d8cf5c7 to 7
  Normal  ScalingReplicaSet  2m23s                   deployment-controller  Scaled up replica set deployment-example-856f4d77d5 to 6
  Normal  ScalingReplicaSet  2m14s (x11 over 2m22s)  deployment-controller  (combined from similar events): Scaled down replica set deployment-example-d9d8cf5c7 to 0
````

Here it triggers a new replica set. Because we changed the pod template.

Note the port is updated

````shell script
➤ k get deploy deployment-example -n testapi -o yaml | grep containerPort
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"proj":"scoulomb"},"name":"deployment-example","namespace":"testapi"},"spec":{"replicas":10,"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"nginx"}},"template":{"metadata":{"labels":{"app":"nginx"}},"spec":{"containers":[{"image":"nginx:1.14","name":"nginx","ports":[{"containerPort":8080}]}]}}}}
                  k:{"containerPort":8080,"protocol":"TCP"}:
                    f:containerPort: {}
        - containerPort: 8080
````

For example if in v3 manifest (and not via imperative command as before) I just change number of replicas of second deployment.
No rs is triggered.

````shell script
k diff -f 4-Analysis/3-c-imperative-declarative/v3 -n testapi
k apply -f 4-Analysis/3-c-imperative-declarative/v3 -n testapi
k describe deployment.apps/deployment-2-example -n testapi | grep -B 4 -A 15 Events
````

output is

````shell script
➤ k describe deployment.apps/deployment-2-example -n testapi | grep -B 4 -A 15 Events
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   deployment-2-example-d9d8cf5c7 (15/15 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  12m   deployment-controller  Scaled up replica set deployment-2-example-d9d8cf5c7 to 5
  Normal  ScalingReplicaSet  22s   deployment-controller  Scaled up replica set deployment-2-example-d9d8cf5c7 to 15
````

How to delete? with delcarative approach? use option `--prune` with a label.
**Source**: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/#how-to-delete-objects

````shell script
k get deploy -l proj=scoulomb -n testapi
k apply -f 4-Analysis/3-c-imperative-declarative/v3 -n testapi --prune -l proj=scoulomb
k get deploy -l proj=scoulomb -n testapi
````

output is 

````shell script
➤ k apply -f 4-Analysis/3-c-imperative-declarative/v3 -n testapi --prune -l proj=scoulomb
deployment.apps/deployment-2-example unchanged
Warning: extensions/v1beta1 Ingress is deprecated in v1.14+, unavailable in v1.22+; use networking.k8s.io/v1 Ingress
deployment.apps/deployment-example pruned
````

### Experience 2

Note namespace is `-n testapi` but we can define define also it in yaml.

````shell script
k apply -f 4-Analysis/3-c-imperative-declarative/deployment-test-ns.yaml
````

Otherwise it is default.

But then consistency is needed 

````shell script
➤ k apply -f 4-Analysis/3-c-imperative-declarative/deployment-test-ns.yaml -n default
error: the namespace from the provided object "testapi" does not match the namespace "default". You must pass '--namespace=testapi' to perform this operation.
````

It is similar to API behavior seen [here](3-a-towards-a-k8s-like-api-explore-k8s-api.md#conclusion-redundancy).

### Experience 3

In [experience 1](#experience-1) we had seen the field `metadata.annotations.kubectl.kubernetes.io/last-applied-configuration`.

This field enables to retains writes made to live objects without merging the changes back into the object configuration files

See 
- example: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/#how-to-update-objects
- and merge patch calculation: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/#merge-patch-calculation

In [experience 1](#experience-1), number of replicas was set in the manifest.
Here we will not define it, and show the # of replicas set with imperative command was retained, due to the merge patch process which is:

````shell script
1. Calculate the fields to delete. These are the fields present in last-applied-configuration and missing from the configuration file.
2. Calculate the fields to add or set. These are the fields present in the configuration file whose values don't match the live configuration.
3. Update `metadata.annotations.kubectl.kubernetes.io/last-applied-configuration`
4. Merge the results from 1, 2, 3 into a single patch request to the API server
````

We will also shown an example of field addition (container port) and deletion (label).

````shell script
➤ diff 4-Analysis/3-c-imperative-declarative/va 4-Analysis/3-c-imperative-declarative/vb
diff 4-Analysis/3-c-imperative-declarative/va/deployment1.yaml 4-Analysis/3-c-imperative-declarative/vb/deployment1.yaml
7d6
<     toto: tutu
20c19,21
<         image: nginx:1.14
\ No newline at end of file
---
>         image: nginx:1.14
>         ports:
>         - containerPort: 80
\ No newline at end of file
````

So

````shell script
k create ns testapi3
k apply -f 4-Analysis/3-c-imperative-declarative/va -n testapi3
k scale deployment.apps/deployment-example --replicas=25 -n testapi3
````
and check status

````shell script
k get deployment deployment-example -n testapi3 -o yaml | grep replicas
k get deployment deployment-example -n testapi3 -o yaml | grep containerPort
k get deployment deployment-example -n testapi3 -o yaml | grep toto
````

output is 

````shell script
➤ k get deployment deployment-example -n testapi3 -o yaml | grep replicas
        f:replicas: {}
        f:replicas: {}
  replicas: 25
  replicas: 25
➤ k get deployment deployment-example -n testapi3 -o yaml | grep containerPort
[20:20][master]⚡✖? ~/dev/my_DNS
➤ k get deployment deployment-example -n testapi3 -o yaml | grep toto
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"proj":"scoulomb","toto":"tutu"},"name":"deployment-example","namespace":"testapi3"},"spec":{"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"nginx"}},"template":{"metadata":{"labels":{"app":"nginx"}},"spec":{"containers":[{"image":"nginx:1.14","name":"nginx"}]}}}}
    toto: tutu
          f:toto: {}
````

After `scale`, replicas is not present in annotation and now present in spec.

If we apply vb

````shell script
k apply -f 4-Analysis/3-c-imperative-declarative/vb -n testapi3
````

Then status output is 

````shell script
[20:22][master]⚡✖? ~/dev/my_DNS
➤ k get deployment deployment-example -n testapi3 -o yaml | grep replicas
        f:replicas: {}
        f:replicas: {}
  replicas: 25
  replicas: 25
[20:22][master]⚡✖? ~/dev/my_DNS
➤ k get deployment deployment-example -n testapi3 -o yaml | grep containerPort
      {"apiVersion":"apps/v1","kind":"Deployment","metadata":{"annotations":{},"labels":{"proj":"scoulomb"},"name":"deployment-example","namespace":"testapi3"},"spec":{"revisionHistoryLimit":10,"selector":{"matchLabels":{"app":"nginx"}},"template":{"metadata":{"labels":{"app":"nginx"}},"spec":{"containers":[{"image":"nginx:1.14","name":"nginx","ports":[{"containerPort":80}]}]}}}}
                  k:{"containerPort":80,"protocol":"TCP"}:
                    f:containerPort: {}
        - containerPort: 80
[20:22][master]⚡✖? ~/dev/my_DNS
➤ k get deployment deployment-example -n testapi3 -o yaml | grep toto
[20:22][master]⚡✖? ~/dev/my_DNS
````

We can see number of replicas is retained, 
The replicas field retains the value of 25 set by `kubectl scale`. This is possible because it is omitted from the configuration file.
ContainerPort is added and label is removed.
Annotation is updated (as inside annotation we have container port, label and no replicas)


### Comment 

Given the definiton made [above](#rephrasing), We understand:

- Imperative commands: declarative object are abstracted
- Imperative object configuration: objects are declarative but we manipulate them imperatively: do a create, then update and delete.
When we apply several time the same configuration we have an error (as the API `POST` (though it is a declarative rest API)).
- Declarative object configuration. We do not have to mention the operation.
When we apply several time the same configuration we do not have an error (as the API `PUT`).
 

### Details

See:
* [Managing Kubernetes Objects Using Imperative Commands][1]
* [Imperative Management of Kubernetes Objects Using Configuration Files][2]
* [Declarative Management of Kubernetes Objects Using Configuration Files][3]


[1]: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/imperative-command/
[2]: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/imperative-config/
[3]: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/


Note Operators use the same rest API as the Kubectl [cf. here](3-a-towards-a-k8s-like-api-explore-k8s-api.md#apply-vs-create).

## application on own API

<!-- dns application

page Imperative+VS+Declarative+API partially correct based on this findings.
I remove what I said about the fact kubernetes API is imperative, as it was clearly wrong

- auto API is already declarative

-->

- a REST API POST with duplicate entry key (name) can actually return a 409 whether we are imperative or declarative. 
<!-- (what we do now, where before duplicate was silently ignored based on the name). -->
But we could make it idempotent for same payload: import existing conf  in blueprint format, make the diff with all attributes (not only primary a key). If there is a diff, raise a 40

Implement idempotency in POST, outside of this particular case,  could be a bad idea based on:  [RFC 7231](#comments-on-post-and-retry)

- if we create automation API on top external device API, we can offer own declarative API + idempotency exposed via automation PUT and do the merge/diff.
<!-- import existing conf in blueprint format, make the diff and reinject config gaps to the device (device PATCH/PUT).-->
This is what `apply/replace` is doing (on top of kubernetes REST API PATCH/PUT itself, it is a layer above) 
and same apply for AS3 (layer above F5 big ip API).
<!--
See https://stackoverflow.com/questions/65225688/why-kubernetes-rest-api-is-imperative (from your link, the Kubernetes API works exactly the same when you apply yaml-manifest files using e.g. kubectl apply -f deployment.yaml)
-->
Same apply for k8s operator. Automation would be at that level.

<!--
+e s b conf eng
-->

<!--
That way procedure to update an already existing object seems solved.
Use case to think is fallback of a modify, which is working well with blueprint -->

<!-- section concluded, OK !! -->
 
