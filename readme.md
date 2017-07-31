## Use Minikube that uses Docker 17.05

Multistage builds are only possible with Docker 17.05+. You can use this
version of minikube until its version of k8s updates its version of docker.

https://github.com/kubernetes/minikube/pull/1542#issuecomment-318683859

    minikube start --iso-url=https://storage.googleapis.com/minikube-builds/1542/minikube-testing.iso --disk-size=60g --memory=4096

    docker version

## Installing/Upgrading Application

    make upgrade

## Debugging MongoDB

    apk --update add mongodb
    mongo go-learn-local-mongodb/test
    db.animal.insertOne({name: 'Foo'})
    db.animal.find()

## Todo

 * Add standardized logging
