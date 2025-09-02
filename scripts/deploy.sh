#!/bin/bash
set -e

# -----------------------------
# Configuration
# -----------------------------
PROJECT_ID="gei-iq"
REGION="asia-south1"
CLUSTER_NAME="flask-demo-cluster"
BUCKET_NAME="flask-demo-uploads"
IMAGE_NAME="flask-gcs-demo"
IMAGE_TAG="latest"
REPO_NAME="flask-repo"

# Docker registry
REGISTRY="asia-south1-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$IMAGE_TAG"

# -----------------------------
# 1 Create GCS bucket
# -----------------------------
echo "Creating GCS bucket: $BUCKET_NAME"
gsutil mb -l $REGION gs://$BUCKET_NAME/ || echo "Bucket may already exist"

# -----------------------------
# 2️Create GKE cluster
# -----------------------------
echo "Creating GKE cluster: $CLUSTER_NAME"
gcloud container clusters create $CLUSTER_NAME \
  --region $REGION \
  --num-nodes 2 \
  --machine-type e2-standard-4 \
  --enable-autoscaling --min-nodes 2 --max-nodes 4 \
  --enable-stackdriver-kubernetes \
  --quiet

# Get credentials for kubectl
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

# -----------------------------
# 3️ Build & push Docker image
# -----------------------------
echo "Building Docker image"
docker build -t $IMAGE_NAME ../app/

echo "Tagging Docker image for Artifact Registry"
docker tag $IMAGE_NAME $REGISTRY

echo "Pushing Docker image"
docker push $REGISTRY

# -----------------------------
# 4️ Apply Kubernetes manifests
# -----------------------------
echo "Applying Kubernetes manifests"
kubectl apply -f ../k8s/

# -----------------------------
# 5️ Wait for LoadBalancer IP
# -----------------------------
echo "Waiting for Flask LoadBalancer IP..."
LB_IP=""
while [ -z "$LB_IP" ]; do
  LB_IP=$(kubectl get svc flask-gcs-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  [ -z "$LB_IP" ] && sleep 5
done
echo "Flask app is available at http://$LB_IP"

# -----------------------------
# 6️ Example curl commands
# -----------------------------
echo -e "\n Example curl commands:"
echo "Health check: curl http://$LB_IP/up-returns"
echo "Add user: curl -X POST http://$LB_IP/add -H 'Content-Type: application/json' -d '{\"name\":\"Bharath\"}'"
echo "List users: curl http://$LB_IP/list"
echo "Upload file: curl -F 'file=@test.txt' http://$LB_IP/upload"
echo "Get file: curl http://$LB_IP/file/test.txt"

