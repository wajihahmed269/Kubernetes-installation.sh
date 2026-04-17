# Kubernetes-installation.sh


# 🚀 Kubernetes Auto Installer

This project provides an interactive shell script to quickly install different Kubernetes environments on a fresh server (e.g., AWS EC2, Ubuntu VM).

---

## 📦 Supported Installations

* Minikube (local Kubernetes)
* K3s (lightweight Kubernetes)
* Kind (Kubernetes in Docker)
* kubeadm (full production-grade cluster setup)

---

## ⚙️ Requirements

Before running the script, make sure:

* You are using a Linux system (Ubuntu recommended)
* You have `sudo` privileges
* Internet connection is active

---

## 🛠️ Pre-Setup Commands (Run FIRST)

Update your system:

```bash
sudo apt update && sudo apt upgrade -y
```

Install Git (if not installed):

```bash
sudo apt install git -y
```

---

## ⬇️ Getting Started

Clone the repository:

```bash
git clone https://github.com/your-username/k8s-installer.git
cd k8s-installer
```

Give execution permission:

```bash
chmod +x install.sh
```

Run the installer:

```bash
./install.sh
```

---

## 🧠 How It Works

* Script shows an interactive menu
* You select the Kubernetes tool
* Script installs required dependencies automatically
* Sets up the cluster environment
* Verifies installation

---

## 📌 What Happens Internally

Depending on your selection:

* Installs container runtime (Docker or containerd if required)
* Installs kubectl
* Sets up Kubernetes cluster
* Disables swap (required for Kubernetes)
* Configures system settings

---

## ✅ After Installation

Verify cluster:

```bash
kubectl get nodes
```

If successful, you’ll see your node in "Ready" state.

---

## 🔧 Optional Next Steps

You can install additional tools:

### Install Helm (recommended)

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Kubernetes Dashboard

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```

---

## ⚠️ Notes

* Do NOT run this script on production servers without reviewing it
* kubeadm setup may require additional networking configuration (CNI)
* K3s is recommended for lightweight environments
* Kind requires Docker

---

## 💡 Future Improvements

* Add support for multiple nodes
* Add monitoring stack (Prometheus + Grafana)
* Add cloud-specific automation (AWS, GCP)

---

## 👨‍💻 Author

Built for learning and DevOps automation practice.
