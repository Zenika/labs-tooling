# CI/CD Platform Deployment

This guide describes the *feature branch* workflow we now use everyday, based on Google's managed Kubernetes (GKE).
Each of our projects has its own namespace in Kubernetes. Every new feature is implemented in a new branch.
As shown in the provided [sample project](sample_project), our CI/CD pipeline allows us to create and maintain an
application instance per feature branch, accessible from anywhere (web) and at anytime.
This scheme goes in the direction of our *Definition of Done*, which requires a code review and a validation from a
Product Owner on a production-like environment before deploying to production.

The following guide contains a lot of data and commands gathered from the following resources:
- [Kubernetes' Quickstart](https://cloud.google.com/kubernetes-engine/docs/quickstart)
- [Traefik's official documentation](https://docs.traefik.io)

Read them in details if you want to deep dive into how things work.


## Architecture and outline

Our pipeline uses GitHub for version control, CircleCI for CI/CD, a Google Kubernetes Engine cluster as the deployment
platform, Traefik as ingress controller and load balancer and Let's Encrypt for a fully automated TLS certificates
management. The corresponding architecture is pictured below:

![architecture](architecture.png)

The following sections will describe how to assemble these components step by step in order for you to reproduce our 
pipeline on your own environments in just a few minutes!


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
- htpasswd

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
our domain is registered with AWS, we use Traefik's Route53 provider to do so (other providers are listed 
[here](https://docs.traefik.io/https/acme/#dnschallenge)). This provider requires the Access Key ID and the Secret 
Access Key of an AWS IAM user with sufficient permissions to edit DNS records.

Fill the following placeholders in the [traefik descriptor](traefik.yaml): 
- `DOMAIN`: the domain you own (e.g., `mywebsite.com`)
- `ACME_EMAIL_ADDRESS`: the contact email address to use to generate the TLS certificates
- `AWS_ACCESS_KEY_ID`: the Access Key ID of the AWS IAM user
- `AWS_SECRET_ACCESS_KEY`: the Secret Access Key of the AWS IAM user
- `AWS_REGION`: the code of your AWS region (can be found in the url when editing your DNS configuration).
- `AWS_HOSTED_ZONE_ID`: the ID of the Hosted Zone in Route53 (can be found in the url when editing your DNS configuration)

Then apply it:
```shell script
kubectl apply -f traefik.yaml
```

This will:
- instantiate a Traefik instance using a Deployment
- expose this Traefik instance on a public IP using a Service of type LoadBalancer
- configure Traefik's entrypoints to listen to ports 80 (http) and 443 (https)
- redirect all http (port 80) traffic to the https entrypoint (port 443) using a RedirectScheme middleware
- expose Traefik's dashboard on the `traefik` subdomain (e.g., `traefik.mywebsite.com`) using an IngressRoute, protected
with a BasicAuth middleware (using the secret created above)
- configure a Traefik certificate resolver to generate wildcard certificates on demand
- create and use the wildcard TLS certificate (e.g., `*.mywebsite.com`) required by the dashboard IngressRoute 

Wait for a bit and get the public IP associated by GKE to the Traefik service:
```shell script
kubectl -n traefik get services
```
The IP will eventually be displayed in the "EXTERNAL-IP" column, but it may take a few seconds.

Configure your DNS records manually to redirect all traffic from your domain to this IP (this is an `A` record from 
`*.mywebsite.com` to the external IP).

Traefik's dashboard should now be accessible on the traefik subdomain (e.g., `traefik.mywebsite.com`) and all http
traffic should be redirected to https with valid Let's Encrypt certificates.
