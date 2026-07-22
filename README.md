# Wisecow — Accuknox DevOps Trainee Assessment

ఈ repo లో మూడు Problem Statements (PS1, PS2, PS3) కి సంబంధించిన artifacts అన్నీ ఉన్నాయి.
దిగువ steps మీ own GitHub repo లో నిజంగా చేయాల్సినవి — వివరంగా తెలుగులో ఇచ్చాను.

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

### Step 1: సొంత GitHub repo create చేయండి
1. GitHub లో login అయ్యి కొత్త **public** repository create చేయండి (assessment prerequisite ప్రకారం repo public గా ఉండాలి). పేరు: `wisecow` అని పెట్టుకోండి.
2. ఈ ఫోల్డర్ మొత్తం (`wisecow-deploy` లోని అన్ని files) ఆ repo లోకి push చేయండి:
   ```bash
   git init
   git remote add origin https://github.com/<your-username>/wisecow.git
   git add .
   git commit -m "Initial commit: Dockerfile, k8s manifests, CI/CD, scripts, kubearmor policy"
   git branch -M main
   git push -u origin main
   ```

### Step 2: Docker image local గా build & test చేయండి
```bash
docker build -t wisecow:local .
docker run -p 4499:4499 wisecow:local
# వేరే terminal లో:
curl http://localhost:4499
```
ఇది cowsay output తో fortune quote ఇస్తే — Dockerfile సరిగ్గా పనిచేస్తుంది అని అర్థం.

### Step 3: Kind/Minikube cluster start చేయండి
```bash
kind create cluster --name wisecow
# లేదా
minikube start
```

### Step 4: Docker Hub కి image push చేయండి
```bash
docker login
docker tag wisecow:local <your-dockerhub-username>/wisecow:latest
docker push <your-dockerhub-username>/wisecow:latest
```
`k8s/deployment.yaml` లో `<DOCKERHUB_USERNAME>` ని మీ actual username తో replace చేయండి.

### Step 5: Kubernetes కి deploy చేయండి
```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl get pods
kubectl get svc
```
App ని access చేయడానికి port-forward:
```bash
kubectl port-forward svc/wisecow-svc 4499:4499
curl http://localhost:4499
```

### Step 6: CI/CD (GitHub Actions)
`.github/workflows/ci-cd.yaml` ఇప్పటికే repo లో ఉంది. ఇది:
- `main` branch కి push చేసినప్పుడల్లా → Docker image build చేసి Docker Hub కి push చేస్తుంది (Continuous Integration).
- తర్వాత మీ cluster లో `kubectl apply` చేసి కొత్త image deploy చేస్తుంది (Continuous Deployment — Challenge Goal).

ఇది పనిచేయాలంటే GitHub repo → **Settings → Secrets and variables → Actions** లో ఈ secrets add చేయాలి:
| Secret name | విలువ |
|---|---|
| `DOCKERHUB_USERNAME` | మీ Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (password కాదు, token) |
| `KUBE_CONFIG` | మీ `~/.kube/config` ఫైల్ ని `base64 -w0 ~/.kube/config` చేసి వచ్చిన string |

> గమనిక: GitHub Actions runner కి మీ Kind/Minikube cluster (ఇది local machine లో ఉంటుంది కాబట్టి) access ఉండదు. Assessment కోసం demo చేయాలంటే self-hosted runner వాడాలి, లేదా cloud cluster (EKS/GKE/AKS) వాడాలి. Deploy job ని optional/manual గా చూపించినా సరిపోతుంది — build & push job మాత్రం ఏ runner మీద అయినా పనిచేస్తుంది.

### Step 7: TLS (Challenge Goal)
Simple & local demo కోసం self-signed certificate వాడదాం:
```bash
# nginx ingress controller install చేయండి
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# self-signed cert generate చేయండి
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=wisecow.local/O=wisecow"

# దాన్ని Kubernetes secret గా create చేయండి
kubectl create secret tls wisecow-tls --key tls.key --cert tls.crt

kubectl apply -f k8s/ingress.yaml
```
`/etc/hosts` లో `127.0.0.1 wisecow.local` add చేసి, `https://wisecow.local` open చేస్తే TLS తో app కనిపిస్తుంది (self-signed కాబట్టి browser warning వస్తుంది — accept చేయండి).
Production లో దీనికి బదులు **cert-manager** + Let's Encrypt వాడితే real, trusted TLS cert వస్తుంది.

---

## PS2 — Scripts (2 ఎంచుకున్నవి: System Health Monitor + Application Health Checker)

### 1. System Health Monitoring — `scripts/system_health_monitor.sh`
CPU, Memory, Disk, process count ని threshold (80%) తో పోల్చి, దాటినప్పుడు `ALERT` అని log చేస్తుంది.
```bash
chmod +x scripts/system_health_monitor.sh
./scripts/system_health_monitor.sh --once      # ఒక్కసారి check
./scripts/system_health_monitor.sh             # ప్రతి 60 సెకన్లకు loop
```
Logs `/var/log/system_health_monitor.log` లో save అవుతాయి (permission లేకపోతే current directory లో).

### 2. Application Health Checker — `scripts/app_health_checker.sh`
ఇచ్చిన URL కి HTTP request పంపి, status code బట్టి app **UP** or **DOWN** అని చెబుతుంది.
```bash
chmod +x scripts/app_health_checker.sh
./scripts/app_health_checker.sh http://localhost:4499
./scripts/app_health_checker.sh http://localhost:4499 --interval 30   # ప్రతి 30 సెకన్లకు check
```

రెండు scripts ని cron job గా కూడా పెట్టుకోవచ్చు (`crontab -e`).

---

## PS3 — KubeArmor Zero-Trust Policy (Optional, extra points)

`kubearmor/wisecow-policy.yaml` లో రెండు policies ఉన్నాయి:
1. **wisecow-allow-baseline** — wisecow.sh కి అవసరమైన binaries (`bash`, `cowsay`, `fortune`, `nc` మొదలైనవి) మాత్రమే allow చేస్తుంది.
2. **wisecow-block-suspicious** — `apt`, `curl`, `wget`, `ssh`, `nmap` లాంటివి explicit గా block చేస్తుంది (ఇవి container breakout/lateral-movement కి వాడే tools).

### Steps:
```bash
# 1. KubeArmor install చేయండి (docs: https://docs.kubearmor.io/kubearmor/quick-links/deployment_guide)
curl -sfL https://raw.githubusercontent.com/kubearmor/kubearmor-client/main/install.sh | sudo sh -s -- -b /usr/local/bin
karmor install

# 2. Policy apply చేయండి
kubectl apply -f kubearmor/wisecow-policy.yaml

# 3. Violation trigger చేయండి (ఇది block అవ్వాలి)
kubectl exec -it <wisecow-pod-name> -- curl https://example.com

# 4. Violation logs చూడండి
karmor logs -n default --json
```
ఇక్కడ వచ్చే `Blocked` alert screenshot తీసి, policy YAML తో పాటు మీ forked repo లో commit చేయండి.

---

## Summary Checklist
- [ ] Dockerfile ✔
- [ ] k8s deployment + service manifests ✔
- [ ] GitHub Actions CI (build & push) ✔
- [ ] GitHub Actions CD (deploy) — Challenge Goal ✔
- [ ] TLS via Ingress + cert — Challenge Goal ✔
- [ ] PS2: 2 scripts (system health monitor + app health checker) ✔
- [ ] PS3: KubeArmor zero-trust policy + violation screenshot (optional)
- [ ] Repo public గా ఉంచడం
