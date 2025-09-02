# GKE Flask-Postgres-GCS Demo

This repository contains a sample Flask application deployed on **Google Kubernetes Engine (GKE)** with **PostgreSQL** and **Google Cloud Storage (GCS)** integration. It includes manifests, a Makefile for one-command deploys, load testing scripts, and example endpoint usage.

---

## Features

- Flask API with endpoints:
  - `/up-returns` – Health check
  - `/add` – Add user
  - `/list` – List users
  - `/upload` – Upload file to GCS bucket
- PostgreSQL backend
- GCS bucket integration for file uploads
- Horizontal Pod Autoscaling (HPA)
- Load testing script for autoscaling demonstration
- One-command deployment using `Makefile`

---

## Prerequisites

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/) (optional)
- GKE cluster with access to deploy applications
- Google Cloud Service Account key (for GCS access)

---

## Setup

1. Clone the repository:
```bash
git clone git@github.com:Bharath-V26/gke-flask-postgres-gcs-demo.git
cd gke-flask-postgres-gcs-demo
```

2. Set up your GKE cluster and context:
```
gcloud container clusters get-credentials <CLUSTER_NAME> --zone <ZONE> --project <PROJECT_ID>
```

3. Make sure the GCS key is not tracked in Git and set the environment variable:
```
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/gcs-key.json"
```

Deployment

You can deploy the entire stack using one command:
```
make deploy
```

This will:

Create the namespace and configmaps

Deploy PostgreSQL and Flask application

Apply the HPA

Wait for pods to be ready
------------------------------------------------------------------------------------------------
Testing Endpoints

After deployment, you can test the endpoints:

Health Check
```
curl -s http://<EXTERNAL_IP>/up-returns; echo
```

Add User
```
curl -s -X POST -H "Content-Type: application/json" -d '{"name":"demo_user"}' http://<EXTERNAL_IP>/add; echo
```

List Users
```
curl -s http://<EXTERNAL_IP>/list; echo
```

Upload File
```
curl -s -F "file=@test.txt" http://<EXTERNAL_IP>/upload; echo
```
------------------------------------------------------------------------------------------------
Load Test / Autoscaling

Trigger a load test to demonstrate autoscaling:
```
make load
```
This uses hey to generate requests and show CPU/memory scaling in real-time via HPA:
```
kubectl get hpa flask-hpa -w
```
You should see replicas increase based on load.
------------------------------------------------------------------------------------------------
Cleanup

Remove all deployed resources:
```
make clean
```
------------------------------------------------------------------------------------------------
Notes

GCS key is ignored in Git (.gitignore) for security

HPA is configured to scale from 2 → 10 replicas based on CPU

Makefile automates deployment, testing, and load testing

Ensure your cluster nodes can handle scaling during load tests

All secrets and sensitive files should never be committed to Git

