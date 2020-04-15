# CI/CD Platform Deployment

As people start new projects, they usually spend some precious time to deploy and configure a CI/CD pipeline. At Zenika
Labs, our goal is to reach proofs of concept or minimum viable products as efficiently as possible, without 
compromising on quality.

This guide shows how to spin up the pipeline we use everyday to build, test and deploy our applications. As demonstrated
at Zenika's Technozaure event on April 3rd, 2018, it can even be achieved in less than an hour!

Since April 2019 and our migration to Google Kubernetes Engine, there are two versions of this guide:
- [Rancher on AWS](rancher-aws), describing the pipeline we previously used (Rancher on RancherOS, AWS)
- [Google Kubernetes Engine](kubernetes-gke), describing the pipeline we use now (Kubernetes, GKE).
