.PHONY: deploy cluster manifests test load clean

# Variables
GCP_PROJECT := gei-iq
REGION := asia-south1
CLUSTER := flask-cluster
GCS_BUCKET := $(USER)-uploads
NAMESPACE := default

# 1. Full deploy: cluster + manifests + test
deploy: cluster manifests test

# 2. Create GKE cluster & GCS bucket
cluster:
	chmod +x infra/setup-gke.sh
	./infra/setup-gke.sh $(GCP_PROJECT) $(REGION) $(CLUSTER) $(GCS_BUCKET)

# 3. Apply Kubernetes manifests
manifests:
	kubectl apply -f k8s/postgres-secret.yaml
	kubectl apply -f k8s/postgres-pvc.yaml
	kubectl apply -f k8s/postgres-statefulset.yaml
	kubectl apply -f k8s/postgres-service.yaml
	kubectl apply -f k8s/flask-config.yaml
	kubectl apply -f k8s/flask-serviceaccount.yaml
	kubectl apply -f k8s/deployment.yaml
	kubectl apply -f k8s/service.yaml
	kubectl apply -f k8s/ingress.yaml
	kubectl apply -f k8s/hpa.yaml

# 4. Run demo curl tests for endpoints
test:
	@echo "Waiting 30s for pods to be ready..."
	sleep 30
	@LB_IP=$$(kubectl get svc flask-gcs-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); \
	echo "Health check:"; \
	curl -s http://$$LB_IP/up-returns; echo; \
	echo "Add user:"; \
	curl -s -X POST -H "Content-Type: application/json" -d '{"name":"demo_user"}' http://$$LB_IP/add; echo; \
	echo "List users:"; \
	curl -s http://$$LB_IP/list; echo; \
	echo "Upload test file:"; \
	curl -s -F "file=@test.txt" http://$$LB_IP/upload; echo

# 5. Load test to trigger autoscaling
load:
	@LB_IP=$$(kubectl get svc flask-gcs-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); \
	echo "Triggering load test..."; \
	hey -z 1m -c 600 http://$$LB_IP/

# 6. Clean cluster resources
clean:
	kubectl delete -f k8s/hpa.yaml
	kubectl delete -f k8s/ingress.yaml
	kubectl delete -f k8s/service.yaml
	kubectl delete -f k8s/deployment.yaml
	kubectl delete -f k8s/flask-serviceaccount.yaml
	kubectl delete -f k8s/flask-config.yaml
	kubectl delete -f k8s/postgres-service.yaml
	kubectl delete -f k8s/postgres-statefulset.yaml
	kubectl delete -f k8s/postgres-pvc.yaml
	kubectl delete -f k8s/postgres-secret.yaml

