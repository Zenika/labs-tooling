# CircleCI Build Docker Image

This repository contains the Dockerfile used to build the 
[zenikalabs/circleci](https://hub.docker.com/r/zenikalabs/circleci/) Docker image. 

This image contains all the binaries we need to build, test and deploy project in CircleCI:
- Node 6.x
- Yarn 1.x
- Java 8 JDK
- Maven
- AWS CLI
- Rancher CLI 0.6.4
- Rancher Compose 0.12.5
- Chrome

For an example of how to use this image, take a look at the CircleCI configuration in the [sample project]()
