#!/bin/bash


# # Install docker
 sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# # Install k3d
 curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# # Create a k3d cluster
 sudo k3d cluster create mycluster

# # Install kubectl
 sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
 sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# # Install Argo CD
sudo kubectl create namespace argocd
 sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# # Wait for Argo CD to be fully deployed
 echo "Waiting for Argo CD to be fully deployed..."
 sudo kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# # Install Argo CD CLI
 sudo curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
 sudo chmod +x /usr/local/bin/argocd

# # Argo CD UI
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# # Print Argo CD initial admin password
 sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

sudo kubectl create namespace dev

sudo kubectl apply -f argo-app.yaml

sudo kubectl port-forward svc/playground-service 8888:80 -n dev