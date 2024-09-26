#!/bin/bash

# Uninstall old versions
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get -y install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker
sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Create a k3d cluster
sudo k3d cluster create mycluster

# Install kubectl
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Argo CD
sudo kubectl create namespace argocd
sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be fully deployed
echo "Waiting for Argo CD to be fully deployed..."
sudo kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Install Argo CD CLI
sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# Store Argo CD initial admin password
ARGOCD_PASSWORD=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# Login to Argo CD
argocd login --insecure --username admin --password $ARGOCD_PASSWORD --grpc-web localhost:8080
# Store the password
echo $ARGOCD_PASSWORD > /home/vagrant/.argocd_password

# # Forward Argo CD UI port
# # A FAIRE A LA MAIN POUR LE MOMENT
# sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# GITHUB_REPO_URL="https://github.com/dbelpaum/myapp.git"
# APP_NAMESPACE="dev"
# APP_NAME="my-app"

# sudo kubectl create namespace $APP_NAMESPACE
# argocd app create $APP_NAME \
#   --repo $GITHUB_REPO_URL \
#   --path dev \
#   --dest-server https://kubernetes.default.svc \
#   --dest-namespace $APP_NAMESPACE \
#   --sync-policy auto \
#   --self-heal

# argocd app sync $APP_NAME

# argocd app get $APP_NAME

# echo "Waiting for the app to be fully deployed..."
# sudo kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=wil-playground -n dev --timeout=600s
# # A FAIRE A LA MAIN POUR LE MOMENT
# sudo kubectl port-forward svc/wil-playground -n dev 8888:8888
