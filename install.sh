#!/bin/bash

set -e

LOG_FILE="install.log"
exec > >(tee -i $LOG_FILE)
exec 2>&1

# =============================
# Utils
# =============================

print_header() {
    echo "======================================"
    echo "🚀 Kubernetes Installer"
    echo "======================================"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "❌ Please run with sudo or as root"
        exit 1
    fi
}

system_prep() {
    echo "📦 Updating system..."
    apt update -y && apt upgrade -y

    apt install -y curl wget git apt-transport-https ca-certificates gnupg lsb-release software-properties-common

    echo "⚙️ Disabling swap..."
    swapoff -a
    sed -i '/ swap / s/^/#/' /etc/fstab
}

# =============================
# LATEST INSTALLS (FIXED)
# =============================

install_kubectl() {
    if command -v kubectl &> /dev/null; then
        echo "✅ kubectl already installed"
        return
    fi

    echo "📦 Installing latest kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl
}

install_docker() {
    if command -v docker &> /dev/null; then
        echo "✅ Docker already installed"
        return
    fi

    echo "🐳 Installing latest Docker..."
    apt remove -y docker docker-engine docker.io containerd runc || true

    apt update
    apt install -y ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker
}

install_containerd() {
    echo "📦 Installing containerd (K8s ready config)..."

    apt install -y containerd

    mkdir -p /etc/containerd
    containerd config default | tee /etc/containerd/config.toml >/dev/null

    # IMPORTANT FIX for kubeadm
    sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true

    systemctl restart containerd
    systemctl enable containerd
}

# =============================
# INSTALLERS
# =============================

install_minikube() {
    echo "🔹 Installing Minikube..."

    install_docker
    install_kubectl

    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    install minikube-linux-amd64 /usr/local/bin/minikube
    rm -f minikube-linux-amd64

    minikube start --driver=docker
    echo "✅ Minikube installed"
}

install_k3s() {
    echo "🔹 Installing K3s (latest)..."

    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="latest" sh -

    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> ~/.bashrc

    echo "✅ K3s installed"
}

install_kind() {
    echo "🔹 Installing Kind (latest)..."

    install_docker
    install_kubectl

    curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x kind
    mv kind /usr/local/bin/kind

    kind create cluster
    echo "✅ Kind cluster created"
}

install_kubeadm() {
    echo "🔹 Installing kubeadm (LATEST STABLE)..."

    install_containerd

    # FIXED NEW REPO (NOT OLD XENIAL)
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
    > /etc/apt/sources.list.d/kubernetes.list

    apt update
    apt install -y kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl

    echo "🚀 Initializing cluster..."
    kubeadm init

    echo "⚙️ Setting kubeconfig..."
    mkdir -p $HOME/.kube
    cp /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config

    export KUBECONFIG=/etc/kubernetes/admin.conf

    echo "🌐 Installing Calico CNI (latest stable)..."
    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

    echo "⏳ Waiting for node readiness..."
    for i in {1..40}; do
        STATUS=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}')
        if [[ "$STATUS" == "Ready" ]]; then
            echo "✅ Cluster Ready!"
            break
        fi
        echo "⏳ Waiting... ($i/40)"
        sleep 5
    done

    kubectl get nodes
    echo "✅ kubeadm setup complete"
}

# =============================
# MENU
# =============================

show_menu() {
    echo ""
    echo "Select Kubernetes setup:"
    echo "1) Minikube"
    echo "2) K3s"
    echo "3) Kind"
    echo "4) kubeadm (Production Ready)"
    echo "5) Exit"
    echo ""
}

handle_choice() {
    read -p "Enter choice: " choice

    case $choice in
        1) install_minikube ;;
        2) install_k3s ;;
        3) install_kind ;;
        4) install_kubeadm ;;
        5) exit 0 ;;
        *) echo "❌ Invalid option"; show_menu; handle_choice ;;
    esac
}

# =============================
# MAIN
# =============================

main() {
    print_header
    check_root
    system_prep
    show_menu
    handle_choice

    echo ""
    echo "🎉 DONE"
}

main
