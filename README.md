# StyleKart — Enterprise DevOps Portfolio Project

> A production-grade fashion e-commerce platform built to demonstrate end-to-end DevOps competency targeting a 2–3 years experience profile.

---

## 🧩 Application Overview

StyleKart is a microservices-based fashion e-commerce application with the following services:

| Service | Language | Port | Description |
|---|---|---|---|
| User Service | Java (Spring Boot) | 8081 | Registration, login, JWT auth |
| Product Service | Java (Spring Boot) | 8082 | Product and category management |
| Order Service | Java (Spring Boot) | 8083 | Order placement and tracking |
| Payment Service | Java (Spring Boot) | 8084 | Payment processing |
| API Gateway | Java (Spring Boot) | 8080 | Single entry point, request routing |
| Frontend | React + Tailwind CSS | 80 | Customer-facing UI |
| PostgreSQL | Docker Official Image | 5432 | Shared database (per-service schemas) |

---

## 🏗️ Architecture

```
Internet
    │
    ▼
AWS ALB (Elastic Load Balancer)
    │
    ├── /api/*  ──► API Gateway (8080)
    │                   ├── User Service (8081)
    │                   ├── Product Service (8082)
    │                   ├── Order Service (8083)
    │                   └── Payment Service (8084)
    │
    └── /*  ──► Frontend (React/Nginx)

All services → PostgreSQL (StatefulSet + EBS CSI)
```
<img width="1024" height="559" alt="image" src="https://github.com/user-attachments/assets/c10b279d-e707-41b6-bea0-89bca3c71004" />

---

## 🛠️ Tech Stack

### Application
- **Backend**: Java 17, Spring Boot, Spring Security, Spring Data JPA
- **Frontend**: React, Tailwind CSS, Axios
- **Database**: PostgreSQL 16

### DevOps
- **Containerization**: Docker (multi-stage builds)
- **Orchestration**: Kubernetes (Minikube locally, EKS on AWS)
- **IaC**: Terraform (modular structure)
- **CI**: Jenkins (parameterised pipeline)
- **Container Registry**: AWS ECR
- **GitOps**: ArgoCD *(upcoming)*
- **Observability**: Prometheus + Grafana + Loki *(upcoming)*

### AWS Services
- **EKS** — Managed Kubernetes
- **ECR** — Private container registry
- **ALB** — Application Load Balancer via AWS Load Balancer Controller
- **EBS** — Persistent storage for PostgreSQL via EBS CSI Driver
- **VPC** — Custom VPC with public/private subnets
- **IAM + IRSA** — Fine-grained pod-level AWS permissions
- **SSM** — Secure EC2 access without SSH

---

## 📁 Repository Structure

```
stylekart/
├── user-service/           # Spring Boot microservice
├── product-service/        # Spring Boot microservice
├── order-service/          # Spring Boot microservice
├── payment-service/        # Spring Boot microservice
├── api-gateway/            # Spring Boot API Gateway
├── frontend/               # React + Tailwind frontend
├── k8s/                    # Kubernetes manifests
│   ├── user-dep.yaml
│   ├── product-dep.yaml
│   ├── order-dep.yaml
│   ├── payment-dep.yaml
│   ├── api-gateway-dep.yaml
│   ├── frontend-dep.yaml
│   ├── postgres-db-statefulset.yaml
│   ├── storageclass.yaml
│   └── ingress.yaml
├── infra/
│   └── environments/
│       └── dev/
│           ├── main.tf
│           └── modules/
│               ├── vpc/
│               ├── eks/
│               ├── irsa/
│               └── ecr/
└── Jenkinsfile
```

---

## ☸️ Kubernetes Setup

### Local (Minikube)
```bash
minikube start
kubectl apply -f k8s/
```

### AWS EKS
Pre-requisites:
- EKS cluster provisioned via Terraform
- EBS CSI Driver installed as EKS add-on
- AWS Load Balancer Controller installed via Helm
- ECR images pushed via Jenkins

```bash
# Configure kubectl
aws eks update-kubeconfig --region ap-south-1 --name stylekart

# Apply manifests
kubectl apply -f k8s/storageclass.yaml
kubectl apply -f k8s/postgres-db-statefulset.yaml
kubectl apply -f k8s/
```

---

## 🏗️ Infrastructure (Terraform)

Modular Terraform structure under `infra/environments/dev/`:

```bash
cd infra/environments/dev

terraform init
terraform apply -target=module.vpc
terraform apply -target=module.eks
terraform apply -target=module.irsa_ebs_csi
terraform apply -target=module.irsa_alb_controller
```

### Modules

| Module | Description |
|---|---|
| `vpc` | VPC, public/private subnets, NAT Gateway, route tables |
| `eks` | EKS cluster, node group, IAM roles, ECR repositories |
| `irsa` | Reusable IRSA module — IAM role + trust policy + policy attachment |

---

## 🔁 CI Pipeline (Jenkins)

Parameterised Jenkins pipeline that builds and pushes any service to ECR:

```
Parameters:
  SERVICE_NAME: [user-service | product-service | order-service | 
                 payment-service | api-gateway-service | frontend-service]

Stages:
  1. Clean workspace
  2. Clone repository
  3. Build Docker image
  4. Push to ECR
```

Trigger a build:
```
Jenkins → New Build with Parameters → Select SERVICE_NAME → Build
```

---

## 🔐 Security Highlights

- **IRSA (IAM Roles for Service Accounts)** — pods get scoped AWS credentials, no hardcoded keys
- **Private EKS endpoint** — cluster API not exposed to internet
- **Private subnets** — worker nodes not directly accessible
- **SSM Session Manager** — EC2 access without SSH or open ports
- **Least privilege IAM** — each component has only the permissions it needs

---

## 🌐 Networking

| Component | Type | Purpose |
|---|---|---|
| ALB | internet-facing | Single entry point for all traffic |
| API Gateway | ClusterIP | Internal service routing |
| Microservices | ClusterIP | Internal only |
| PostgreSQL | Headless Service | StatefulSet DNS |

---

## 🗄️ Database

PostgreSQL runs as a Kubernetes StatefulSet with:
- **EBS CSI Driver** for persistent volume provisioning
- **gp2-csi StorageClass** — AWS CSI provisioner
- **Per-service databases**: `stylekart_users`, `stylekart_products`, `stylekart_orders`, `stylekart_payments`
- **PGDATA** set to subdirectory to avoid EBS `lost+found` conflict

---

## 📌 Key Engineering Decisions

- **IRSA over node-level IAM** — scoped credentials per workload
- **EBS CSI over in-tree driver** — current AWS standard, avoids deprecated `kubernetes.io/aws-ebs`
- **ALB with ip target type** — routes directly to pod IPs, bypasses NodePort
- **WaitForFirstConsumer** — EBS volumes created in same AZ as pod
- **Modular Terraform** — IRSA module reused for EBS, ALB controller, and future components

---

## 🚧 Upcoming

- [ ] ArgoCD — GitOps continuous deployment
- [ ] Prometheus + Grafana — metrics and dashboards
- [ ] Loki — centralized log aggregation
- [ ] Jenkins CD — auto-update image tags post-push
- [ ] Kubernetes Secrets / AWS Secrets Manager — externalize JWT secret

---

## 👨‍💻 Author

**Ayush** — DevOps Engineer  
Building production-grade infrastructure on AWS + Kubernetes
