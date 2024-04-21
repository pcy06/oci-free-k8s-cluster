#!/bin/bash

MASTER_HOST="10.0.1.10:6443"
MASTER_TOKEN="(검열됨)"
MASTER_CA_CERT_HASH="(검열됨)"

# sudo iptables-save > ~/iptables-rules

# grep -v "DROP" iptables-rules > tmpfile && mv tmpfile iptables-rules-mod
# grep -v "REJECT" iptables-rules-mod > tmpfile && mv tmpfile iptables-rules-mod

# sudo iptables-restore < ~/iptables-rules-mod

# sudo netfilter-persistent save
# sudo systemctl restart iptables

sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt update

sudo apt install -y containerd.io

sudo systemctl enable containerd
sudo systemctl start containerd

sudo modprobe br_netfilter
sudo modprobe overlay

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a && sudo sed -i '/swap/s/^/#/' /etc/fstab

sudo mkdir -p /etc/containerd/

containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

while true; do
    sudo kubeadm join $MASTER_HOST --token $MASTER_TOKEN --discovery-token-ca-cert-hash $MASTER_CA_CERT_HASH

    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "Worker Node Initalization done successfully."
        break
    else
        echo "Worker Node Initalization failed with exit code $exit_code. Retrying..."
        sleep 3
    fi
done