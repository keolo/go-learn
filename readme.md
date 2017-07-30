## Build application and image

    docker build -t go-learn .

## Deploy release

    helm install go-learn --name=go-learn

## Delete release

    helm delete go-learn --purge

## View application in browser

    minikube service go-learn

## Socat

    socat tcp-listen:HOST_PORT,reuseaddr,fork tcp:SERVICE_IP:SERVICE_PORT

## Use Minikube that uses Docker 17.05

Multistage builds are only possible with Docker 17.05+. You can use this
version of minikube until its version of k8s updates its version of docker.

https://github.com/kubernetes/minikube/pull/1542#issuecomment-318683859

    docker version
