CLUSTER   ?= skillpulse
NAMESPACE ?= skillpulse
BACKEND_IMAGE  ?= haider3897/skillpulse-backend
FRONTEND_IMAGE ?= haider3897/skillpulse-frontend
TAG       ?= latest

.PHONY: up down build load apply status logs mysql restart

build:
	docker build -t $(BACKEND_IMAGE):$(TAG) ./backend
	docker build -t $(FRONTEND_IMAGE):$(TAG) ./frontend

load:
	kind load docker-image $(BACKEND_IMAGE):$(TAG) --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE):$(TAG) --name $(CLUSTER)

apply:
	kubectl apply -f k8s/00-namespace.yaml -f k8s/10-mysql.yaml -f k8s/20-backend.yaml -f k8s/30-frontend.yaml
	kubectl rollout status statefulset/mysql -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend -n $(NAMESPACE) --timeout=60s

status:
	kubectl get pods,svc,endpoints -n $(NAMESPACE)

down:
	kind delete cluster --name $(CLUSTER)

restart:
	$(MAKE) build
	$(MAKE) load
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)
