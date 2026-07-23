<<<<<<< HEAD
# Wisecow — Accuknox DevOps Trainee Assessment

This repo contains all the artifacts for Problem Statements 1, 2, and 3.
The steps below are what you actually need to do in your own GitHub repo.

```
wisecow-deploy/
├── Dockerfile
├── wisecow.sh
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── .github/workflows/ci-cd.yaml
├── scripts/
│   ├── system_health_monitor.sh
│   └── app_health_checker.sh
└── kubearmor/
    └── wisecow-policy.yaml
```

---

## PS1 — Containerisation & Kubernetes Deployment

### Step 1: Create your own GitHub repo
1. Log in to GitHub and create a new **public** repository (the assessment requires the repo to be public). Name it `wisecow`.
2. Push this entire folder (all files inside `wisecow-deploy`) to that repo:
   ```bash
   git init
   git remote add origin https://github.com/<your-username>/wisecow.git
   git add .
   git commit -m "Initial commit: Dockerfile, k8s manifests, CI/CD, scripts, kubearmor policy"
   git branch -M main
   git push -u origin main
   ```

### Step 2: Build & test the Docker image locally
```bash
docker build -t wisecow:local .
docker run -p 4499:4499 wisecow:local
# in a separate terminal:
curl http://localhost:4499
```
If this returns cowsay output with a fortune quote, the Dockerfile is working correctly.

### Step 3: Start a Kind/Minikube cluster
```bash
kind create cluster --name wisecow
# or
minikube start
```

### Step 4: Push the image to Docker Hub
```bash
docker login
docker tag wisecow:local <your-dockerhub-username>/wisecow:latest
docker push <your-dockerhub-username>/wisecow:latest
```
Replace `<DOCKERHUB_USERNAME>` in `k8s/deployment.yaml` with your actual Docker Hub username.

### Step 5: Deploy to Kubernetes
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get pods
kubectl get svc
```
To access the app, port-forward:
```bash
kubectl port-forward svc/wisecow-svc 4499:4499
curl http://localhost:4499
```

### Step 6: CI/CD (GitHub Actions)
`.github/workflows/ci-cd.yaml` is already in the repo. It:
- Builds the Docker image and pushes it to Docker Hub whenever you push to the `main` branch (Continuous Integration).
- Then runs `kubectl apply` against your cluster to deploy the new image (Continuous Deployment — Challenge Goal).

For this to work, add the following secrets under your GitHub repo → **Settings → Secrets and variables → Actions**:

| Secret name | Value |
|---|---|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | A Docker Hub access token (not your password) |
| `KUBE_CONFIG` | The output of `base64 -w0 ~/.kube/config` run on your `~/.kube/config` file |

> Note: GitHub Actions runners cannot reach a Kind/Minikube cluster, since it only exists on your local machine. To actually demo Continuous Deployment you'd need a self-hosted runner or a cloud cluster (EKS/GKE/AKS). It's fine to leave the deploy job optional/manual — the build & push job will still work on any runner. (The workflow in this repo already gates the `deploy` job behind a `CD_ENABLED` repository variable so it doesn't fail when there's no reachable cluster.)

### Step 7: TLS (Challenge Goal)
For a simple local demo, use a self-signed certificate:
```bash
# install the nginx ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# generate a self-signed cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=wisecow.local/O=wisecow"

# create it as a Kubernetes secret
kubectl create secret tls wisecow-tls --key tls.key --cert tls.crt

kubectl apply -f k8s/ingress.yaml
```
Add `127.0.0.1 wisecow.local` to your `/etc/hosts` file, then open `https://wisecow.local` — you'll see the app served over TLS (since it's self-signed, your browser will show a warning — accept it to continue).
In production, use **cert-manager** + Let's Encrypt instead, to get a real, trusted TLS certificate.

---

## PS2 — Scripts (2 chosen: System Health Monitor + Application Health Checker)

### 1. System Health Monitoring — `scripts/system_health_monitor.sh`
Compares CPU, Memory, Disk, and process count against an 80% threshold, and logs an `ALERT` whenever a metric crosses it.
```bash
chmod +x scripts/system_health_monitor.sh
./scripts/system_health_monitor.sh --once      # run a single check
./scripts/system_health_monitor.sh             # loop every 60 seconds
```
Logs are saved to `/var/log/system_health_monitor.log` (or the current directory if you don't have write permission there).

### 2. Application Health Checker — `scripts/app_health_checker.sh`
Sends an HTTP request to a given URL and reports whether the app is **UP** or **DOWN** based on the status code.
```bash
chmod +x scripts/app_health_checker.sh
./scripts/app_health_checker.sh http://localhost:4499
./scripts/app_health_checker.sh http://localhost:4499 --interval 30   # check every 30 seconds
```

Both scripts can also be scheduled as cron jobs (`crontab -e`).

---

## PS3 — KubeArmor Zero-Trust Policy (Optional, extra points)

`kubearmor/wisecow-policy.yaml` contains two policies:
1. **wisecow-allow-baseline** — allows only the binaries wisecow.sh actually needs (`bash`, `cowsay`, `fortune`, `nc`, etc.).
2. **wisecow-block-suspicious** — explicitly blocks tools like `apt`, `curl`, `wget`, `ssh`, `nmap` (commonly used for container breakout / lateral movement).

### Steps:
```bash
# 1. Install KubeArmor (docs: https://docs.kubearmor.io/kubearmor/quick-links/deployment_guide)
curl -sfL https://raw.githubusercontent.com/kubearmor/kubearmor-client/main/install.sh | sudo sh -s -- -b /usr/local/bin
karmor install

# 2. Apply the policy
kubectl apply -f kubearmor/wisecow-policy.yaml

# 3. Trigger a violation (this should be blocked)
kubectl exec -it <wisecow-pod-name> -- curl https://example.com

# 4. View violation logs
karmor logs -n default --json
```
Take a screenshot of the resulting `Blocked` alert, and commit it along with the policy YAML to your forked repo.

---

## Summary Checklist
- [ ] Dockerfile ✔
- [ ] k8s deployment + service manifests ✔
- [ ] GitHub Actions CI (build & push) ✔
- [ ] GitHub Actions CD (deploy) — Challenge Goal ✔
- [ ] TLS via Ingress + cert — Challenge Goal ✔
- [ ] PS2: 2 scripts (system health monitor + app health checker) ✔
- [ ] PS3: KubeArmor zero-trust policy + violation screenshot (optional)
<<<<<<< HEAD
- [ ] Repo public గా ఉంచడం
=======
# wisecow
>>>>>>> 99be9e117409e26a689614b4942f81f0ea673857
=======
- [ ] Keep the repo public
>>>>>>> b2ab8b75ac48353bfb6d8128317ad0c6b4db2643
 
