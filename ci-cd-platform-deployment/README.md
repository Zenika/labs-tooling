# CI/CD Platform Deployment

As teams start new projects, they usually waste precious time deploying and configuring a CI/CD pipeline from scratch.
At Zenika Labs, our goal is to deliver proofs of concept or minimum viable products as efficiently as possible, without
compromising on quality.

Our teams usually work on short-lived (from a few minutes to a few hours) *feature branches*, with a strong focus on 
technical/functional exploration and quick iterations with the Product Owner. We expect our infrastructure to be able to
deploy a new version of the product in a few minutes, but also to dynamically deploy an instance for each active feature
branch on each Git push. These production-like instances, accessible from anywhere (web) and at any time, are targeted 
by automated end-to-end tests, used by the Product Owner to try new features, and sometimes showed to the end users to 
validate or invalidate new concepts and ideas.

We work on a large range of technical stacks and on very diverse products, from static websites to complex event-driven
microservices architectures. We need to deploy both stateless and stateful workloads, some very light such as Node.js 
backends, others more compute or data-intensive such as Kafka clusters. Build processes also vary from trivial to very 
complex in the case of large microservice architectures in a monorepo.

In any case, our job is not to build or maintain infrastructures, but rather to deliver software. This is why we want to
reuse most of our tooling across projects and need language, architecture and size-agnostic services. Moreover, the
price of most managed services for CI/CD are so low compared to a developer daily cost that there is no actual reason 
for us not to use them extensively and focus our precious time on more useful work.

This guide describes how to set up, in probably *less than an hour*, the infrastructure supporting the development 
workflow we use every day to build, test and deploy our projects. For all the reasons listed above and after a lot of 
investigation, we settled on Google's managed Kubernetes (GKE) as well as CircleCI, Traefik and other Google Cloud 
services.

**What is Kubernetes?**
> Kubernetes, also known as k8s, is an open-source system for automating deployment, scaling, and management of 
containerized applications. In the past years, Kubernetes has become the de-facto industrial standard to deploy 
containers on-premise or in the cloud.

We use a shared, autoscaling Kubernetes cluster as an all-purpose (and now quite standard) deployment target. Each of 
our projects has its own namespace, with resources quotas et closed network boundaries.

If you have never used Kubernetes before, this guide will probably feel a bit too hard to follow. You may start by
[reading a bit about Kubernetes](https://kubernetes.io/docs/concepts/overview/) first.


**What is CircleCI?**
> CircleCI is a cloud-native continuous integration and continuous delivery (CI/CD) platform. It integrates with GitHub
and Bitbucket and runs a configured pipeline on each commit. Think Jenkins multibranch pipelines on steroids, in the 
cloud, and fully managed for you.

We chose CircleCI as a managed, modern and reliable alternative to Jenkins and prefer it over TravisCI or GitHub Actions 
for its best-in-class performance and ability to configure and run workflows on large polyglot monorepos requiring 
advanced caching mechanisms.
 
If you have never used CircleCI before, welcome aboard and enjoy the [free plan](https://circleci.com/pricing/)!

**What is Traefik?**
> Traefik Proxy is a dynamic, modern, open-source Edge Router that automatically inspects your infrastructure to
discover services and how to route traffic to them. Traefik is natively compliant with every major cluster technology, 
such as Kubernetes, Docker, Docker Swarm, AWS, Mesos, Marathon... and even bare metal! Used as an ingress controller in 
Kubernetes, it is probably a drop-in replacement for the one you already use (if any), and brings awesome features such 
as automated TLS certificate management via Let's Encrypt, middlewares, plugins...

Traefik is the cornerstone of our platform, allowing new instances to be deployed and made accessible over `https` 
without any human intervention. 

If you have never used Traefik before, welcome aboard and enjoy the ride (you will)!


The following guide contains some data and commands gathered from the following resources:
- [Kubernetes' Quickstart](https://cloud.google.com/kubernetes-engine/docs/quickstart)
- [Traefik's official documentation](https://docs.traefik.io)

Read them in details if you want to deep dive into how things work.


## Architecture and outline

Our pipeline uses GitHub for version control, CircleCI for CI/CD, a Google Kubernetes Engine cluster as the deployment
platform, Traefik as ingress controller and load balancer and Let's Encrypt for a fully automated and free TLS 
certificate management. The corresponding architecture is pictured below:

![architecture](architecture.png)

Everytime a developers pushes a new feature branch on GitHub, the platform builds it and deploys it to an isolated,
short-lived environment (`App 1`, ..., `App n` in the picture above). This new, separate instance of the app is made
accessible on the web with a dedicated URL and a TLS certificate, allowing the team and our users to test it in a 
production-like environment. In this setup `master` in just another instance of the app which can act as an integration
environment.

The following sections will describe how to assemble step by step the different components pictured above in order to 
reproduce our pipeline on your own environments in about an hour.


## Requirements

For that, you will need
- a Google Cloud account, with full access rights to create and configure a Kubernetes cluster
- a GitHub account, with ability to create and configure projects
- a CircleCI account linked to your GitHub account, with ability to configure and run builds
- to own a domain (e.g., `mywebsite.com`) managed by one of the providers 
[compatible with Traefik](https://docs.traefik.io/https/acme/#dnschallenge)

The following command-line tools must be installed and configured on your computer:
- [gcloud SDK](https://cloud.google.com/sdk/docs/quickstarts)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- htpasswd  (`sudo apt-get install htapasswd`)
- envsubst (`sudo apt-get install gettext`)

Login in gcloud (this command should open a page in your browser asking for access to your Google account):
```shell script
gcloud auth login
```


## 1. Kubernetes cluster

### Deploy a GKE cluster instance on GCP

This can easily be done through the [Cloud Console](https://console.cloud.google.com/kubernetes). The following
instructions do not assume a particular configuration or size for your cluster, except for the HTTP load balancing
add-on, which must be enabled after creation.

### Authenticate to the cluster:

```shell script
gcloud container clusters get-credentials [CLUSTER_NAME]
```


## 2. Traefik

### Create a "traefik" namespace in the cluster

```shell script
kubectl create namespace traefik
```

### Import Traefik's Custom Resource Definitions (CRDs) in the cluster

Apply the [CRD descriptor](crd.yaml):
```shell script
kubectl apply -f crd.yaml
```

### Apply the Role-Based Access Control (RBAC) rules required by Traefik

Apply the [RBAC descriptor](rbac.yaml):
```shell script
kubectl apply -f rbac.yaml
```

This will create the RBAC rules, create a service account for Traefik and bind the rules to the service account.

### Deploy Traefik in the cluster

Create a secret file with a pair user / password hash. These will be the credentials to use to access Traefik's 
dashboard.
```shell script
htpasswd -bc [FILENAME] [USER] [PASSWORD]
```

Import the secret into your cluster's traefik namespace:
```shell script
kubectl create secret generic traefik-auth --from-file [FILENAME] --namespace=traefik
```

In order for Traefik to generate wildcard TLS certificates using Let's Encrypt, it must fulfill a DNS challenge. Since 
our domain is registered with Google Domains and our DNS is handled by Google Cloud DNS, we use Traefik's Google Cloud
provider to do so (other providers are listed [here](https://docs.traefik.io/https/acme/#dnschallenge)). This provider
requires the key of a GCP Service Account with DNS write access to edit DNS records. This service account and its key
can be generated through the [Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts). 

Note that if you opt for another provider, you will probably need to adapt or remove the `volume`, `volumeMount` and 
environment variables parts of the [traefik descriptor](traefik.yaml) in order to pass the correct configuration to 
Traefik.

Import the key file into your cluster's traefik namespace as a secret with key `traefik-service-account`:
```shell script
kubectl create secret generic traefik-service-account --from-file=traefik-service-account.json=[FILENAME] --namespace=traefik
```

Fill the following placeholders in the [traefik descriptor](traefik.yaml): 
- `DOMAIN`: the domain you own (e.g., `mywebsite.com`)
- `ACME_EMAIL_ADDRESS`: the contact email address to use to generate the TLS certificates
- `GCE_PROJECT`: the name of the Google Cloud project

> a script is at your disposal to create the taraefik-apply.yaml file from the traefik.yaml template, this script needs as input the values of the variables (below) and then it will take care of replacing everything

Then apply it:
```shell script
sh scripts/traefik-apply.sh
kubectl apply -f traefik-apply.yaml
```

This will:
- instantiate a Traefik instance using a Deployment
- expose this Traefik instance on a public IP using a Service of type LoadBalancer
- configure Traefik's entrypoints to listen to ports 80 (HTTP) and 443 (HTTPS)
- redirect all HTTP (port 80) traffic to the HTTPS entrypoint (port 443) using a RedirectScheme middleware
- expose Traefik's dashboard on the `traefik` subdomain (e.g., `traefik.mywebsite.com`) using an IngressRoute, protected
with a BasicAuth middleware (using the secret created above)
- configure a Traefik certificate resolver to generate wildcard certificates on demand
- create and use the wildcard TLS certificate (e.g., `*.mywebsite.com`) required by the dashboard IngressRoute 

Wait for a bit and get the public IP associated by GKE to the Traefik Service:
```shell script
kubectl -n traefik get services
```
The IP will eventually be displayed in the "EXTERNAL-IP" column, but it may take a few seconds.

Configure your DNS records manually to redirect all traffic from your domain to this IP (this is an `A` record from 
`*.mywebsite.com` to the external IP).

Traefik's dashboard should now be accessible on the traefik subdomain (e.g., `traefik.mywebsite.com`) and all HTTP
traffic should be redirected to HTTPS with valid Let's Encrypt certificates.


## 3. A first "whoami" toy project

In this section, we will illustrate how to use Traefik to expose multiple instances/branches/versions of a same app on 
subdomains. Suppose we chose to dedicate the `whoami` subdomain (e.g., `whoami.mywebsite.com`) to this project. Our goal
is to expose the master version of the app on a `master` subdomain (e.g., `master.whoami.mywebsite.com`) and the changes
of a `feature1` branch on the `feature1` subdomain (e.g., `feature1.whoami.mywebsite.com`).

For this example, we will use the containous/whoami Docker image as a dummy web application, which only serves some 
information about the server and the received request for any request on port 80. 

### Create a namespace for the project

```shell script
kubectl create namespace whoami
```

### Deploy the master version

Fill the following placeholders in the [whoami-master descriptor](whoami-master.yaml): 
- `DOMAIN`: the domain you own (e.g., `mywebsite.com`)

Then apply it:
```shell script
kubectl apply -f whoami-master.yaml
```

This will instantiate 3 instances of the `whoami` Pod, create a Service to load balance between them, and expose this
Service through an IngressRoute. Notice the use of the `traefik` TLS certificate resolver created in step 2, the 
request for a `*.whoami.[DOMAIN]` wildcard certificate and the use of the `master.whoami.[DOMAIN]` Host rule to route
traffic to this URL to our Service. In just a few seconds, the certificate is generated and your application server is
exposed securely on the `master.whoami` of your domain (try it!). 

### Deploy the feature1 branch

Fill the following placeholders in the [whoami-branch1 descriptor](whoami-branch1.yaml): 
- `DOMAIN`: the domain you own (e.g., `mywebsite.com`)

Then apply it:
```shell script
kubectl apply -f whoami-branch1.yaml
```

This will instantiate 3 new instances of the Pod, create a new Service to load balance between them, and expose this
Service through an IngressRoute. Notice again the use of the `traefik` TLS certificate resolver created in step 2, the 
request for a `*.whoami.[DOMAIN]` wildcard certificate (which is already managed by Traefik and will be reused) and the 
use of the `branch1.whoami.[DOMAIN]` Host rule to route traffic to this URL to our Service. Your new app instance,
distinct from the master environment is already live (try it!). 

### Use a template

Notice the very few differences between the [whoami-master](whoami-master.yaml) and the 
[whoami-branch1](whoami-branch1.yaml) descriptors: all occurences of `master` have simply be replaced by `branch1`. In 
real world use cases, the Docker image will probably be different too.

Take a look at the [whoami-template descriptor template](whoami-template.yaml) file. Env-like placeholders (e.g., 
`${INSTANCE_NAME}`) are used. We will use the `envsubst` tool to instantiate our template.

Fill the following placeholders in the [whoami-template descriptor template](whoami-template.yaml): 
- `DOMAIN`: the domain you own (e.g., `mywebsite.com`)
Do not touch the env-like placeholders.

Set the required environement variables, then instantiate the template and apply it: 
```shell script
export INSTANCE_NAME=branch2
export IMAGE=containous/whoami:v1.5.0
envsubst < whoami-template.yaml > whoami-branch2.yaml
kubectl apply -f whoami-branch2.yaml
```

Quick, your `branch2` instance is already up!

The `envsubst` approach will get you quite far, but look into [Kustomize](https://github.com/kubernetes-sigs/kustomize)
or [Helm](https://helm.sh/) if you need a more advanced configuration management tool.



## 4. A "myapp" project with CI/CD

In this section, we will illustrate how the manual deployment described in step 3 can be integrated in about any CI/CD
pipeline. Suppose we chose to dedicate the `myapp` subdomain (e.g., `myapp.mywebsite.com`) to this project. Our goal
is to expose any branch X on the X subdomain (e.g., branch `feat1` exposed on `feat1.myapp.mywebsite.com`, `feat2`
exposed on `feat2.myapp.mywebsite.com`, etc.).

For this example, we will build our own Docker image in a CircleCI pipeline. For the sake of simplicity, this guide will
use the same containous/whoami image, but feel free to build your own for real! 

### Create a namespace for the project

```shell script
kubectl create namespace myapp
```

### Create a "myapp" project on GitHub

In the [sample_project](sample_project) folder, fill the following placeholders in the 
[myapp-template descriptor](sample_project/myapp-template.yaml): 
- `DOMAIN`: the domain you own (e.g., `mywebsite.com`)

Then push the content of the [sample_project](sample_project) folder at the root of your GitHub repository (i.e., the 
`.circleci` folder, the `Dockerfile` and the descriptor template should be visible at the root of your repository).

Notice in particular the [.circleci/config.yml](sample_project/.circleci/config.yml) build configuration file for 
CircleCI (more about the syntax [here](https://circleci.com/docs/2.0/configuration-reference/)).

### Create a CircleCI service account on GCP

This can easily be done in the [Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts).

Create a new `CircleCI` account with role `Storage Admin` and `Kubernetes Engine Admin`. Create and download a (JSON) 
key for this account. This technical user will have write access to the Google Container Registry (GCR) of you project 
and permission to deploy to your cluster.


### Build the project on CircleCI

In CircleCI, add your project in the build list in the `Add Projects` tab (use the `Add manually` button, since you have
already committed a `.circleci/config.yml` file).

In the `Settings` tab, find your project in the `Projects` sub-tab and open its settings.

In `Environment Variables`, create the following variables. They are used in the CircleCI configuration and in the
descriptor template.
- `GCP_PROJECT`: The id of your GCP project (visible in the 
[Cloud Console](https://console.cloud.google.com/home/))
- `GCP_AUTH`: The content of the JSON key file created in the previous step.
- `GCP_REGISTRY`: The GCR registry of your choice (`eu.gcr.io/[GCP_PROJECT]` for a storage in Europe)
- `GCP_ZONE`: The GCP Zone in which your cluster is hosted (visible in the 
[Cloud Console](https://console.cloud.google.com/kubernetes/list), e.g., `europe-west3-a`)
- `GCP_KUBE_CLUSTER`: The name of your Kubernetes cluster

Relaunch the build: the master branch is deployed on the `master` subdomain (e.g., `master.myapp.mywebsite.com`).

Create branches on your GitHub repository and push them... and let the magic happen! From source code to production in 
less than 20 seconds!

![Screenshot CircleCI](screenshot_circleci.png)



## 5. Bonus track: delete stale instances in Kubernetes

Now you know how to deploy an instance of your app per GitHub branch in Kubernetes... But how to delete stale instances
in Kubernetes (instances of the app created for branches that are since deleted in GitHub)?

### Add a second job in your CircleCI configuration

As you can see, it involves quite a bit of bash wizardry...

```yaml
jobs:
  build:
    [...]
  delete-stale-ci-stacks:
    docker:
      - image: google/cloud-sdk
    working_directory: /home/circleci/myapp
    steps:
      - checkout
      - run:
        name: Authenticate with GCP
        command: |
          echo ${GCP_AUTH} > /home/circleci/gcp-key.json
          gcloud auth activate-service-account --key-file /home/circleci/gcp-key.json
          gcloud --quiet config set project ${GCP_PROJECT}
          gcloud config set compute/zone ${GCP_ZONE}
          gcloud --quiet container clusters get-credentials ${GCP_KUBE_CLUSTER}
      - run:
        name: Delete stale instances
        command: |
          KUBE_FEATURE_BRANCHES=`kubectl get po -n myapp -l 'app.kubernetes.io/name=myapp' -o jsonpath="{.items[*].metadata.labels['app\.kubernetes\.io/instance']}"`
          GIT_BRANCHES=`git branch --list --remote | sed 's/  origin\///g'`
          for kube_branch in $KUBE_FEATURE_BRANCHES; do
            echo "Checking branch ${kube_branch}"
            git_branch_still_exists=false
            for git_branch in $GIT_BRANCHES; do
              if [ "${git_branch}" == "${kube_branch}" ]; then
                git_branch_still_exists=true
                echo "Git branch ${git_branch} still exists, instance ${kube_branch} will not be deleted."
              fi
            done
            if [ "${git_branch_still_exists}" = false ]; then
              echo "Git branch corresponding to instance ${kube_branch} has been deleted, deleting instance..."
              kubectl delete all,ingressroute -n myapp -l app.kubernetes.io/instance=$kube_branch
            fi
          done
```

### Add the job in a new workflow triggered by a CRON

```yaml
workflows:
  version: 2
  build-test-and-deploy:
    [...]
  delete-stale-deployments:
    triggers:
      - schedule:
        cron: "0 0,6,12,18 * * *" # Every six hours
        filters:
          branches:
            only:
              - master
    jobs:
          - delete-stale-ci-stacks
``` 

## Conclusion

For a toy project, the cost of this infrastructure is about $100 a month. For real-world projects with large 
architectures we average $500 per project per month, and the *pay-as-you-go* pricing model of the services we use 
guarantees this cost to be quite linear. This might look like a lot, but in fact it is ridiculously low when you take
into account the billable time not spent on maintaining this type of platform ourselves (or being slowed down by it!).

As of this writing, we have been using these tools and techniques for all our projects at Zenika Labs for more than two
years. Feel free to use it, share it, suggest improvements or ask any question!
