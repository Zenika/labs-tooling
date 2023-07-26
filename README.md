# Labs Tooling

This repository is dedicated to sharing tools used and/or developed at [Zenika Labs](https://zenika.github.io/labs).

Each directory contains a tool or a guide with a corresponding README.

Pull requests are welcome!


# GCP

TO deploy the infrastructure with kubernetes we need:

* Create the GCS bucket to store the tf state
```bash
# With the -b on flag, versioning is enabled for the bucket
gsutil mb -p zenika-lbas -c STANDARD -l europe-west1 -b on gs://zenika-labs-bucket-tfstate/

```

* Use the service account `terraform-automation` if not exist create it using the following script:

````bash
chmod +x scripts/iam-binding.sh
sh scripts/iam-binding.sh
````

* Enable Service Usage API

```bash
gcloud services enable serviceusage.googleapis.com --project=zenika-labs
gcloud services enable storage.googleapis.com --project=zenika-labs
gcloud services enable container.googleapis.com --project=zenika-labs
gcloud services enable compute.googleapis.com --project=zenika-labs
gcloud services enable iam.googleapis.com --project=zenika-labs
```
