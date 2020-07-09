# Towards a k8s like API:  Kube API exploration 

## Setup

````
sudo minikube start --vm-driver=none

k delete ns testapi
k delete ns testapi2

# https://github.com/scoulomb/myk8s/blob/7c530b14194d95ca7176a9077cf27782679f5fa2/Deployment/advanced/container-port.md
k proxy --port=8080 # Launch with sudo on minikube oterwise 401 error 

# In second window check API is working
curl http://localhost:8080/api/

````


## Create a pod with API

Doc: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#-strong-write-operations-pod-v1-core-strong-

API path is `POST /api/v1/namespaces/{namespace}/pods`

And body can be generated with:

````
k run nginx --image=nginx --restart=Never --dry-run=client -o json
=> {"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}

````

So we will create pod `nginx-via-api` in ns `testapi`

````shell script
k create ns testapi

curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'

k get pods -n testapi
````

Output is

````
➤ k get pods -n testapi                                                                                                                                                       vagrant@archlinuxNAME            READY   STATUS    RESTARTS   AGE
nginx-via-api   1/1     Running   0          6m43s
````

Note that pod name in post is not accepted:

````shell script
➤ curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api  -d \                                                   vagrant@archlinux
  '{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'

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

## GET a pod content via API

````
curl -H 'content-type: application/json' -X GET http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api
````

Output is:

````
➤ curl -H 'content-type: application/json' -X GET http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api                                                          vagrant@archlinux{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "nginx-via-api",
    "namespace": "testapi",
    "selfLink": "/api/v1/namespaces/testapi/pods/nginx-via-api",
    "uid": "c8148a82-aea8-493f-bf57-9e4aeb997993",
    "resourceVersion": "23665",
    "creationTimestamp": "2020-07-08T09:24:18Z",
    "labels": {
      "run": "nginx"
    },
````

## PUT to modify a Pod

````
curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'
````

This lead to the error even when no  change or when just changing the image 

````
  "status": "Failure",
  "message": "Pod \"nginx-via-api\" is invalid: spec: Forbidden: pod updates may not change fields other than `spec.containers[*].image`, `spec.initContainers[*].image`, `spec.activeDeadlineSeconds` or `spec.tolerations` (only additions to existing tolerations)\n  core.PodSpec{\n- \tVolumes:
  ````

From: https://blog.nillsf.com/index.php/2019/08/05/ckad-series-part-6-pod-design/
Do edit or delete and apply

This gave me the idea to export manifest and change version of nginx in exported file

````
k get pods nginx-via-api -n testapi --export -o json > poddata.json
````

````
➤ cat poddata.json | head -n 5                                                                                                                                                vagrant@archlinux{
    "apiVersion": "v1",
    "kind": "Pod",
    "metadata": {
        "creationTimestamp": null,

➤ cat poddata.json | grep -C 5 namespace                                                                                                                                      vagrant@archlinux
                "operation": "Update",
                "time": "2020-07-08T12:03:15Z"
            }
        ],
        "name": "nginx-via-api",
        "selfLink": "/api/v1/namespaces/testapi/pods/nginx-via-api"
    },
    "spec": {
        "containers": [
            {
                "image": "nginx",

````
Note in metadata we have name and self link but not the namespace.
 
Change the version:

````shell script
sed 's/"image": "nginx"/"image": "nginx:1.18.0"/g' poddata.json > newpoddata.json
diff poddata.json newpoddata.json
````


And apply via API

````
curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api  -d @newpoddata.json
k describe po nginx-via-api -n testapi | grep -A 20 Events
````

The pod started container with new version

output is 
````
➤ k describe po nginx-via-api -n testapi | grep -A 20 Events                                                                                                                  vagrant@archlinuxEvents:
  Type    Reason     Age                  From                Message
  ----    ------     ----                 ----                -------
  Normal  Scheduled  <unknown>            default-scheduler   Successfully assigned testapi/nginx-via-api to archlinux
  Normal  Pulling    6m25s                kubelet, archlinux  Pulling image "nginx"
  Normal  Pulled     6m23s                kubelet, archlinux  Successfully pulled image "nginx"
  Normal  Killing    28s                  kubelet, archlinux  Container nginx definition changed, will be restarted
  Normal  Pulling    28s                  kubelet, archlinux  Pulling image "nginx:1.18.0"
  Normal  Created    25s (x2 over 6m23s)  kubelet, archlinux  Created container nginx
  Normal  Started    25s (x2 over 6m23s)  kubelet, archlinux  Started container nginx
  Normal  Pulled     25s                  kubelet, archlinux  Successfully pulled image "nginx:1.18.0"
````

## Delete 

````
curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api 
````
               
## Recreate same pod

````shell script
k get po -n testapi
curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods -d @newpoddata.json
k get po -n testapi
````

Output is 


````shell script
➤ k get po -n testapi                                                                                                                                                         vagrant@archlinux
No resources found in testapi namespace.

➤ curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods -d @newpoddata.json                                                   vagrant@archlinux

{
  "kind": "Pod",
  "apiVersion": "v1",
[...]

  "status": {
    "phase": "Pending",
    "qosClass": "BestEffort"
  }
}⏎

➤ k get po -n testapi                                                                                                                                                         vagrant@archlinux
NAME            READY   STATUS    RESTARTS   AGE
nginx-via-api   1/1     Running   0          6s
````

## What happens if i recreate with same @newpoddata.json which has the name but not the same ns as in body selflink

````
[12:11] ~
➤ cat newpoddata.json | grep testapi                                                                                                                                          vagrant@archlinux
        "selfLink": "/api/v1/namespaces/testapi/pods/nginx-via-api"
[12:11] ~

````
so we do

````shell script
k create ns testapi2
curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi2/pods  -d @newpoddata.json
k get pods -n testapi2
k get pods -n testapi2 -o json | grep testapi
````


Output of get pods is

````
NAME            READY   STATUS              RESTARTS   AGE
nginx-via-api   0/1     ContainerCreating   0          2m29s
                "namespace": "testapi2",
                "selfLink": "/api/v1/namespaces/testapi2/pods/nginx-via-api",
````

namespace is added here.
Then as default secret token is not found it does not deploy. but it is something different,

And clean-up

````
k delete pod nginx-via-api -n testapi2 --force --grace-period=0
or
curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api  
k delete testapi2
````

## Create with inconsistent namespace between body and API path

(body optional metadata.namespace)



````
➤ cat newpoddata.json | grep namespace                                                                                                                                        vagrant@archlinux
        "selfLink": "/api/v1/namespaces/testapi/pods/nginx-via-api"
````


Add namespace wiht Jq

````shell script
https://stackoverflow.com/questions/49632521/how-to-add-a-field-to-a-json-object-with-the-jq-command
cat newpoddata.json | jq '.metadata.namespace+="testapi"' > newpoddatawithns.json

````

And apply

````

curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi2/pods  -d @newpoddatawithns.json
k create ns testapi2
curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi2/pods  -d @newpoddatawithns.json
````

Output is 

````shell script
➤ curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi2/pods  -d @newpoddatawithns.json                                           vagrant@archlinux

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "namespaces \"testapi2\" not found",
  "reason": "NotFound",
  "details": {
    "name": "testapi2",
    "kind": "namespaces"
  },
  "code": 404
}⏎
[12:45] ~
➤ k create ns testapi2                                                                                                                                                        vagrant@archlinuxnamespace/testapi2 created
[12:45] ~
➤ curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi2/pods  -d @newpoddatawithns.json                                           vagrant@archlinux

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "the namespace of the provided object does not match the namespace sent on the request",
  "reason": "BadRequest",
  "code": 400
}⏎
[12:45] ~
````

And kubernetes is doing the check as seen in output


## What happens if i update a pod where name in path is different from name in body 

I take example made [here](#put-to-modify-a-pod)

````shell script

sed 's/"image": "nginx"/"image": "nginx:1.18.0"/g' poddata.json > newpoddata-inconsistent.json
cat poddata.json | jq '.metadata.name="nginx-via-api-inconsistent"' > newpoddata-inconsistent.json

curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api  -d @newpoddata-inconsistent.json
````

Output is 

````shell script
➤ curl -H 'content-type: application/json' -X PUT http://localhost:8080/api/v1/namespaces/testapi/pods/nginx-via-api  -d @newpoddata-inconsistent.json                        vagrant@archlinux

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "the name of the object (nginx-via-api-inconsistent) does not match the name on the URL (nginx-via-api)",
  "reason": "BadRequest",
  "code": 400
}⏎
````

Note no need to have pod running

````shell script
➤ k get po -n testapi                                                                                                                                                         vagrant@archlinux
No resources found in testapi namespace.
````
A check is done

## Delete pod with body

https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#deleteoptions-v1-meta

````shell script
curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never", "terminationGracePeriodSeconds": 0}}'


curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never", "gracePeriodSeconds": 0}}'

curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods
````

output is 

````shell script
[12:47] ~
➤ curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods  -d \                                                               vagrant@archlinux
  '{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never", "gracePeriodSeconds": 0}}'

{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "converting (v1.Pod) to (v1.DeleteOptions): GracePeriodSeconds not present in src",
  "code": 500
}⏎
[12:48] ~
➤ curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods                                                                     vagrant@archlinux{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/namespaces/testapi/pods",
    "resourceVersion": "50339"
  },
````


Adding field GracePeriodSeconds, terminationGracePeriods seconds changes nothing in delete body

## List pods

````shell script
curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api1","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'

curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api2","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'


curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi/pods  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api3","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'


curl -H 'content-type: application/json' -X GET http://localhost:8080/api/v1/namespaces/testapi/pods
````

Output is 

````shell script
➤ curl -H 'content-type: application/json' -X GET http://localhost:8080/api/v1/namespaces/testapi/pods                                                                        vagrant@archlinux{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/namespaces/testapi/pods",
    "resourceVersion": "80362"
  },
  "items": [
    {
      "metadata": {
        "name": "nginx-via-api1",
        "namespace": "testapi",
[...]
````
**And we can also delete as a list**

````shell script
curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi/pods
k get po -n testapi     
````

Output is 

````shell script
➤ k get po -n testapi                                                                                                                                                         vagrant@archlinuxNAME             READY   STATUS        RESTARTS   AGE
nginx-via-api1   0/1     Terminating   0          113s
nginx-via-api2   0/1     Terminating   0          113s
nginx-via-api3   0/1     Terminating   0          113s
````

## List pods in different ns

````shell script
curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi2/pods  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api1","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'

curl -H 'content-type: application/json' -X POST http://localhost:8080/api/v1/namespaces/testapi2/pods  -d \
'{"kind":"Pod","apiVersion":"v1","metadata":{"name":"nginx-via-api2","labels":{"run":"nginx"}},"spec":{"containers":[{"name":"nginx","image":"nginx"}],"restartPolicy":"Never"}}'


curl -H 'content-type: application/json' -X GET http://localhost:8080/api/v1/pods

````

And in watch mode 

````shell script
curl -H 'content-type: application/json' -X GET 'http://localhost:8080/api/v1/pods?watch'
# Fish need '' in endpoint
````

And clean 

````shell script
curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi2/pods  
curl -H 'content-type: application/json' -X DELETE http://localhost:8080/api/v1/namespaces/testapi2/pods  
````

## Clean-up global

````
k delete ns testapi
k delete ns testapi2
````

## Documentation

From: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#create-pod-v1-core


| Type | Operation         | HTTP method |  Path                                               | Body
| ---- | ------------      | ----------- | --------------------------------------------------   | ------------------
|Write | create POD        | POST        | `/api/v1/namespaces/{namespace}/pods`                | [Pod](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#pod-v1-core)
|Write | create Eviction   | POST        | `/api/v1/namespaces/{namespace}/pods/{name}/eviction`| [Eviction](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#eviction-v1beta1-policy)
|Write | patch             | PATCH       | `/api/v1/namespaces/{namespace}/pods/{name}`         | [Patch](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#patch-v1-meta)
|Write | replace           | PUT         | `/api/v1/namespaces/{namespace}/pods/{name}`         | [Pod](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#pod-v1-core)
|Write | delete            | DELETE      | `/api/v1/namespaces/{namespace}/pods/{name}`         | [Delete options](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#deleteoptions-v1-meta)
|Write | delete collection | DELETE      | `/api/v1/namespaces/{namespace}/pods`                | [Delete options](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.18/#deleteoptions-v1-meta)

| Type | Operation         | HTTP method |  Path                                               | Body
| ---- | ------------      | ----------- | --------------------------------------------------  | ------------------
|Read  | Read              | GET         | `/api/v1/namespaces/{namespace}/pods/{name}`        | Empty
|Read  | List              | GET         | `/api/v1/namespaces/{namespace}/pods`               | Empty
|Read  | List all ns       | GET         | `/api/v1/pods/`                                     | Empty

In old API version we had watch equivalent under `/api/v1/wacth`, it is now a query parameter



## Conclusion redundancy

**API server metadata ns and name are redundant with API path**

For
- `Write/create POD`: `{namespace}` in PATH is redundant with `.body.metadata.namespace`.
If they are not compliant we are rejected as seen [above](#Create-with-inconsistent-namespace-between-body-and-API-path)
- For `Write/replace`: Same is true for  namespace, but it is also the case for the `{name}` in path and `.body.metadata.name`.
As seen also [here](#what-happens-if-i-update-a-pod-where-name-in-path-is-different-from-name-in-body).

In context of GitOps it is interesting to have this metadata for controller to determine which API path to target.
Also for listing operation,
 
`apiVersion` in body also redundant with path. 


#### Side Notes
 
##### Labels/annotations are in metadata and not at top level

````shell script
➤ k create deployment toto --image=nginx --dry-run=client -o yaml | head -n 10                                                                                                vagrant@archlinuxapiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: toto
  name: toto
spec:
  replicas: 1
  selector:


➤ k get deployment toto -o yaml | head -n 5                                                                                                                                   vagrant@archlinuxapiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
````

##### Apply vs create

See [myk8s here](https://github.com/scoulomb/myk8s/blob/7c530b14194d95ca7176a9077cf27782679f5fa2/Deployment/advanced/article.md#load-new-software-version-v2-and-trigger-a-new-deployment) and [here](https://github.com/scoulomb/myk8s/blob/1e2db05beff94342a751767ffd28493568044423/Master-Kubectl/cheatsheet.md#generate-manifest):
In kubectl we can easily guess (not checked):
- `k apply` is declarative (if resource does not exist do `POST`, if exist perform diff and `PUT/PATCH` new conf) 
- `k create/run` is imperative (`POST` and error if object is not created).
If need update need `k replace` which will do the PUT.

We can see go client is used in kubectl:
- https://github.com/kubernetes/client-go/blob/cf84c08bad11b3ad990800f50914f8114d28a6c3/kubernetes/typed/core/v1/pod.go#L115
- https://github.com/kubernetes/kubectl/blob/d838edc0263aa1efd6c533d880c0f111567e57f1/pkg/cmd/run/run.go#L39