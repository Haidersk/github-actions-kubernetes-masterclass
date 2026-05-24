cat > /var/lib/jenkins/workspace/skillpulse-pipeline/Makefile << 'EOF'
CLUSTER   ?= skillpulse
NAMESPACE ?= skillpulse
BACKEND_IMAGE  ?= haider3897/skillpulse-backend
FRONTEND_IMAGE ?= haider3897/skillpulse-frontend
TAG       ?= latest

.PHONY: up down build load apply status logs mysql restart

up:
	$(MAKE) build
	kind create cluster --config k8s/kind-config.yaml --name $(CLUSTER)
	$(MAKE) load
	$(MAKE) apply
	@echo "SkillPulse is live at http://localhost:8888"

build:
	docker build -t $(BACKEND_IMAGE):$(TAG)  ./backend
	docker build -t $(FRONTEND_IMAGE):$(TAG) ./frontend
	@echo "=== Built Images ==="
	@docker images | grep skillpulse

load:
	kind load docker-image $(BACKEND_IMAGE):$(TAG)  --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE):$(TAG) --name $(CLUSTER)

apply:
	kubectl apply -f k8s/00-namespace.yaml \
	              -f k8s/10-mysql.yaml \
	              -f k8s/20-backend.yaml \
	              -f k8s/30-frontend.yaml
	kubectl rollout status statefulset/mysql    -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend   -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend  -n $(NAMESPACE) --timeout=60s

status:
	@kubectl get pods,svc,endpoints -n $(NAMESPACE)

logs:
	@kubectl logs -n $(NAMESPACE) -l 'app in (mysql,backend,frontend)' --all-containers --tail=50 -f --max-log-requests=10

mysql:
	kubectl exec -it -n $(NAMESPACE) mysql-0 -- mysql -uskillpulse -pskillpulse123 skillpulse

down:
	kind delete cluster --name $(CLUSTER)

restart:
	$(MAKE) build
	$(MAKE) load
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)
	kubectl rollout status  deployment/backend  -n $(NAMESPACE) --timeout=120s
	kubectl rollout status  deployment/frontend -n $(NAMESPACE) --timeout=60s
EOF
