.PHONY: deploy cluster manifests test load clean

# Variables
GCP_PROJECT := gei-iq
REGION := asia-south1
CLUSTER := flask-demo-cluster
GCS_BUCKET := flask-demo
NAMESPACE := default

# 1. Deploy cluster + bucket
cluster:
	chmod +x scripts/create_gke.sh
	./scripts/create_gke.sh $(GCP_PROJECT) $(REGION) $(CLUSTER) $(GCS_BUCKET)

# 2. Apply Kubernetes manifests
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

# 3. Run demo curl tests for each endpoint
test:
	@echo "Waiting 30s for pods to be ready..."
	sleep 30
	@echo "Hit health check:"
	curl -s http://$(shell kubectl get svc flask-gcs-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/up-returns; echo
	@echo "Add user:"
	curl -s -X POST -H "Content-Type: application/json" -d '{"name":"demo_user"}' http://$(shell kubectl get svc flask-gcs-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/add; echo
	@echo "List users:"
	curl -s http://$(shell kubectl get svc flask-gcs-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/list; echo
	@echo "Upload test file:"
	curl -s -F "file=@test.txt" http://$(shell kubectl get svc flask-gcs-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/upload; echo

# 4. Load test example to trigger autoscaling
load:
	@echo "Triggering load test (CPU/memory autoscaling)..."
	hey -z 1m -c 600 http://$(shell kubectl get svc flask-gcs-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/

# 5. Clean cluster resources
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

