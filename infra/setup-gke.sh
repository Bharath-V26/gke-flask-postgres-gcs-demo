#!/bin/bash
set -e

# 1. Set GCP project and region
PROJECT_ID="gei-iq"
REGION="asia-south1"
ZONE="asia-south1-a"
CLUSTER_NAME="flask-cluster"

gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# 2. Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable storage-component.googleapis.com

# 3. Create GCS bucket
BUCKET_NAME="${USER}-uploads"
gsutil mb -l $REGION gs://$BUCKET_NAME/

# 4. Create a regional GKE cluster
gcloud container clusters create $CLUSTER_NAME \
  --region $REGION \
  --num-nodes 2 \
  --machine-type e2-standard-4 \
  --enable-autoscaling --min-nodes=2 --max-nodes=10 \
  --enable-ip-alias \
  --enable-autorepair \
  --enable-autoupgrade \
  --metadata disable-legacy-endpoints=true

# 5. Get credentials
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

echo "Cluster and bucket created!"
echo "GCS bucket: gs://$BUCKET_NAME"

