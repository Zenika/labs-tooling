SERVICE_ACCOUNT="terraform-automation"
PROJECT_ID="zenika-labs"

# Create the service account
gcloud iam service-accounts create $SERVICE_ACCOUNT --display-name="Terraform Automation Service Account"

# Roles to attach to the service account
ROLES=(
  "roles/artifactregistry.admin"
  "roles/compute.networkAdmin"
  "roles/container.admin"
  "roles/iam.serviceAccountCreator"
  "roles/iam.serviceAccountUser"
  "roles/iam.serviceAccountDeleter"
  "roles/resourcemanager.organizationAdmin"
  "roles/resourcemanager.projectIamAdmin"
  "roles/servicemanagement.quotaAdmin"
  "roles/serviceusage.serviceUsageAdmin"
  "roles/storage.admin"
)

for ROLE in "${ROLES[@]}"; do
  # Attach the roles to the service account
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="$ROLE"
done
